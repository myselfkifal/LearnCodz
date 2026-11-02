import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quizquest/cloud_progress.dart';

const userA = '11111111-1111-4111-8111-111111111111';
const userB = '22222222-2222-4222-8222-222222222222';
Future<void> session(SupabaseClient client, String id) async {
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'sub': id, 'exp': 4102444800})))
      .replaceAll('=', '');
  await client.auth.setInitialSession(jsonEncode({
    'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.signature',
    'refresh_token': 'test-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': 4102444800,
    'user': {
      'id': id,
      'aud': 'authenticated',
      'email': 'test@example.test',
      'app_metadata': {},
      'user_metadata': {},
      'created_at': '2026-01-01T00:00:00Z'
    }
  }));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Backup rejects malformed types before altering local data', () {
    expect(() => ProgressSnapshot.validate({'avatar': 'wrong'}),
        throwsFormatException);
    expect(() => ProgressSnapshot.validate({'scores': false}),
        throwsFormatException);
  });
  test('Snapshot excludes tokens and metadata and preserves drafts/settings',
      () async {
    SharedPreferences.setMockInitialValues({
      'scores': '{"cpp.hello":3}',
      'codeDraft.python': 'print(1)',
      'cloud.owner': userA,
      'sb-test-auth-token': 'private',
      'avatar': 2,
      'days': ['2026-11-02']
    });
    final prefs = await SharedPreferences.getInstance();
    final snap = ProgressSnapshot.read(prefs);
    expect(snap.keys,
        containsAll(['scores', 'codeDraft.python', 'avatar', 'days']));
    expect(snap.keys.any((k) => k.startsWith('cloud.') || k.startsWith('sb-')),
        false);
    await ProgressSnapshot.apply(
        prefs, {'profileName': 'New', 'soundVolume': 0.5});
    expect(prefs.getString('scores'), null);
    expect(prefs.getString('sb-test-auth-token'), 'private');
    expect(prefs.getDouble('soundVolume'), 0.5);
  });
  Future<(CloudProgress, SupabaseClient)> setup(Map<String, Object> initial,
      Future<http.Response> Function(http.Request) handler) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    final client = SupabaseClient('https://example.supabase.co', 'public-test',
        httpClient: MockClient(handler),
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    await session(client, userA);
    final cloud = CloudProgress(prefs, client);
    addTearDown(() async {
      cloud.dispose();
      await client.dispose();
    });
    return (cloud, client);
  }

  testWidgets('Android back returns within the signed-in account navigator',
      (tester) async {
    final pair = (await tester.runAsync(() => setup({'cloud.owner': userA},
        (r) async => http.Response('[]', 200, request: r))))!;
    final cloud = pair.$1;
    CloudProgress.instance = cloud;
    cloud.ready = true;
    addTearDown(() => CloudProgress.instance = null);
    await tester.pumpWidget(MaterialApp(
        home: CloudGate(
            child: () => Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const Scaffold(
                                    body: Text('Lesson screen')))),
                        child: const Text('Open lesson')))))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson screen'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open lesson'), findsOneWidget);
  });
  test('Existing cloud backup restores before dashboard becomes ready',
      () async {
    final (cloud, _) = await setup(
        {},
        (r) async => http.Response(
            jsonEncode([
              {
                'user_id': userA,
                'revision': 4,
                'state': {'scores': '{"hello":3}', 'profileName': 'Alice'}
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: r));
    await cloud.prepare();
    expect(cloud.ready, true);
    expect(cloud.revision, 4);
    expect(cloud.prefs.getString('profileName'), 'Alice');
    expect(cloud.conflict, false);
  });
  test('Local edits upload with revision filter and only allowed values',
      () async {
    var uploaded = false;
    final (cloud, _) = await setup({
      'cloud.owner': userA,
      'profileName': 'Alice',
      'cloud.cache.$userA': jsonEncode({'revision': 2, 'baseline': '{}'})
    }, (r) async {
      if (r.method == 'PATCH') {
        uploaded = true;
        expect(r.url.queryParameters['revision'], 'eq.2');
        expect(jsonDecode(r.body)['state']['profileName'], 'Alice');
        return http.Response('[{"revision":3}]', 200,
            headers: {'content-type': 'application/json'}, request: r);
      }
      return http.Response('[{"revision":2,"state":{}}]', 200,
          headers: {'content-type': 'application/json'}, request: r);
    });
    await cloud.prepare();
    expect(uploaded, true);
    expect(cloud.revision, 3);
  });
  test('Concurrent cloud changes preserve local edits and block overwrite',
      () async {
    var writes = 0;
    final (cloud, _) = await setup({
      'cloud.owner': userA,
      'profileName': 'Local',
      'cloud.cache.$userA': jsonEncode({'revision': 1, 'baseline': '{}'})
    }, (r) async {
      if (r.method != 'GET') writes++;
      return http.Response(
          '[{"revision":2,"state":{"profileName":"Remote"}}]', 200,
          headers: {'content-type': 'application/json'}, request: r);
    });
    await cloud.prepare();
    expect(cloud.conflict, true);
    expect(writes, 0);
    expect(cloud.prefs.getString('profileName'), 'Local');
  });
  test('Offline login session keeps local changes and retries later', () async {
    final (cloud, _) = await setup(
        {'cloud.owner': userA, 'profileName': 'Offline'},
        (r) async => throw http.ClientException('offline'));
    await cloud.prepare();
    expect(cloud.ready, true);
    expect(cloud.prefs.getString('profileName'), 'Offline');
    expect(cloud.status, contains('saved locally'));
  });
  test(
      'Switching accounts isolates progress and retains previous account cache',
      () async {
    final (cloud, client) = await setup(
        {},
        (r) async => http.Response('[]', 200,
            headers: {'content-type': 'application/json'}, request: r));
    await cloud.prepare();
    await cloud.prefs.setString('profileName', 'Alice');
    await cloud.cache();
    await session(client, userB);
    await cloud.prepare();
    expect(cloud.prefs.getString('profileName'), null);
    await cloud.prefs.setString('profileName', 'Bob');
    await cloud.cache();
    await session(client, userA);
    await cloud.prepare();
    expect(cloud.prefs.getString('profileName'), 'Alice');
  });
  test('Failed conditional update does not claim upload success', () async {
    final (cloud, _) = await setup(
        {
          'cloud.owner': userA,
          'profileName': 'Alice',
          'cloud.cache.$userA': jsonEncode({'revision': 2, 'baseline': '{}'})
        },
        (r) async => http.Response(
            r.method == 'PATCH' ? '[]' : '[{"revision":2,"state":{}}]', 200,
            headers: {'content-type': 'application/json'}, request: r));
    await cloud.prepare();
    expect(cloud.conflict, true);
    expect(cloud.revision, 2);
  });
}
