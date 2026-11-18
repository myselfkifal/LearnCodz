import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quizquest/cloud_progress.dart';
import 'package:quizquest/google_auth.dart';
import 'package:quizquest/backend_config.dart';

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
  test('Google profile fills name and email but preserves edited fields', () {
    final user = User.fromJson({
      'id': userA,
      'aud': 'authenticated',
      'email': 'Coder@gmail.com',
      'app_metadata': {'provider': 'google'},
      'user_metadata': {'full_name': 'Google Coder'},
      'created_at': '2026-01-01T00:00:00Z'
    })!;
    expect(GoogleAuth.profileDefaults(user),
        {'profileName': 'Google Coder', 'profileEmail': 'coder@gmail.com'});
    expect(
        GoogleAuth.profileDefaults(user,
            name: 'My chosen name', email: 'contact@gmail.com'),
        isEmpty);
    expect(GoogleAuth.profileDefaults(user, name: 'My chosen name'),
        {'profileEmail': 'coder@gmail.com'});
    final emailUser = User.fromJson({
      'id': userA,
      'aud': 'authenticated',
      'email': 'coder@gmail.com',
      'app_metadata': {'provider': 'email'},
      'user_metadata': {'full_name': 'Unrelated'},
      'created_at': '2026-01-01T00:00:00Z'
    })!;
    expect(GoogleAuth.profileDefaults(emailUser), isEmpty);
  });
  test('Google setup check prevents browser launch while provider is disabled',
      () async {
    final client = SupabaseClient('https://example.supabase.co', 'public-test',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    var launched = false;
    final transport = MockClient(
        (r) async => http.Response('{"external":{"google":false}}', 200));
    await expectLater(
        GoogleAuth.start(client, settingsClient: transport, launch: () async {
          launched = true;
          return true;
        }),
        throwsA(isA<AuthException>()));
    expect(launched, false);
    transport.close();
  });
  test('Google launch uses provider settings without creating a fake session',
      () async {
    final client = SupabaseClient('https://example.supabase.co', 'public-test',
        authOptions: const AuthClientOptions(autoRefreshToken: false));
    addTearDown(client.dispose);
    final transport = MockClient((r) async {
      expect(r.url.path, '/auth/v1/settings');
      expect(r.headers['apikey'], BackendConfig.publishableKey);
      return http.Response('{"external":{"google":true}}', 200);
    });
    expect(
        await GoogleAuth.start(client,
            settingsClient: transport, launch: () async => true),
        true);
    expect(client.auth.currentSession, null);
    transport.close();
    final link = Uri.parse(BackendConfig.mobileCallback);
    expect(link.scheme, 'com.learncodz.app');
    expect(link.host, 'login-callback');
  });
  testWidgets('OAuth auth event restores progress once before opening the app',
      (tester) async {
    final prefs = (await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      return SharedPreferences.getInstance();
    }))!;
    var reads = 0;
    final client = (await tester.runAsync(() async => SupabaseClient(
            'https://example.supabase.co', 'public-test',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
            httpClient: MockClient((r) async {
          reads++;
          return http.Response(
              '[{"revision":3,"state":{"profileName":"Google learner"}}]', 200,
              request: r, headers: {'content-type': 'application/json'});
        }))))!;
    final cloud = CloudProgress(prefs, client);
    CloudProgress.instance = cloud;
    await tester.pumpWidget(MaterialApp(
        home: CloudGate(
            child: () => const Scaffold(body: Text('Signed in home')))));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.runAsync(() => session(client, userA));
    for (var i = 0; i < 100 && !cloud.ready; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    expect(cloud.ready, true);
    await tester.pumpAndSettle();
    expect(find.text('Signed in home'), findsOneWidget);
    expect(prefs.getString('profileName'), 'Google learner');
    expect(reads, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    cloud.dispose();
    CloudProgress.instance = null;
    await tester.runAsync(client.dispose);
  });
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
  testWidgets(
      'Rounded logout keeps confirmation and signs out only after continue',
      (tester) async {
    final pair = (await tester.runAsync(() => setup(
        {'cloud.owner': userA, 'profileName': 'Learner'},
        (request) async => http.Response('[]', 200,
            headers: {'content-type': 'application/json'},
            request: request))))!;
    final cloud = pair.$1;
    CloudProgress.instance = cloud;
    cloud.ready = true;
    addTearDown(() => CloudProgress.instance = null);
    await tester.pumpWidget(const MaterialApp(
        home:
            Scaffold(body: SingleChildScrollView(child: CloudAccountCard()))));
    await tester.pumpAndSettle();
    expect(find.text('Logout'), findsOneWidget);
    expect(
        find.byWidgetPredicate(
            (widget) => widget is FilledButton && widget.onPressed != null),
        findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cloud.uid, userA);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    for (var i = 0; i < 100 && cloud.uid != null; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    expect(cloud.uid, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
