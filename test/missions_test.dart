import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/code_runner.dart';
import 'package:quizquest/coding_missions.dart';
import 'package:quizquest/cloud_progress.dart';
import 'package:quizquest/language_courses.dart';
import 'package:quizquest/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'monospace': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf'
    }.entries) {
      final font = FontLoader(entry.key)
        ..addFont(File('test/fonts/${entry.value}')
            .readAsBytes()
            .then(ByteData.sublistView));
      await font.load();
    }
  });
  tearDown(() => activeLanguage = null);
  test('Hints identify known errors and avoid guessing unmapped line numbers',
      () {
    final hint = CompilerHint.from(
        'your_code:2: error: expected \';\' before return',
        StudyLanguage.cpp,
        'int n = 2;\ncout << n');
    expect(hint.title, 'A semicolon may be missing');
    expect(hint.line, 2);
    expect(
        CompilerHint.from(
                'Main.java:7: cannot find symbol', StudyLanguage.java, 'x = 1;')
            .line,
        isNull);
    expect(
        CompilerHint.from('File "x.py", line 2\nIndentationError',
                StudyLanguage.python, 'if True:\nprint(1)')
            .title,
        'Check your indentation');
    expect(normalizedOutput('8\r\n'), '8');
    expect(
        CompilerHint.from('prog.java:7: error: cannot find symbol',
                StudyLanguage.java, 'int a = 2;\nSystem.out.println(b);',
                generatedSource: prepareProgram(
                    StudyLanguage.java, 'int a = 2;\nSystem.out.println(b);'))
            .line,
        2);
    for (final lang in StudyLanguage.values) {
      expect(codingMissions.first.starter(lang), isNotEmpty);
      expect(
          codingMissions
              .every((m) => m.cases.length == 3 && m.steps.length == 3),
          isTrue);
    }
  });
  test('Mission and lesson drafts are isolated and included in backup',
      () async {
    SharedPreferences.setMockInitialValues({
      'codeDraft.cpp': 'original',
      'codeDraft.cpp.mission.double': 'mission',
      'codeDraft.cpp.lesson.functions': 'lesson',
      'missionCompletions': ['cpp:double'],
      'seenAchievements': ['First Code'],
      'secret': 'never'
    });
    final snapshot = ProgressSnapshot.validate(
        ProgressSnapshot.read(await SharedPreferences.getInstance()));
    expect(snapshot['codeDraft.cpp'], 'original');
    expect(snapshot['codeDraft.cpp.mission.double'], 'mission');
    expect(snapshot['codeDraft.cpp.lesson.functions'], 'lesson');
    expect(snapshot['missionCompletions'], ['cpp:double']);
    expect(snapshot.containsKey('secret'), isFalse);
  });
  testWidgets(
      'Mission checks real responses and saves completion without replacing playground',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'codeDraft.cpp': 'keep my work'});
    final prefs = await SharedPreferences.getInstance();
    CompilerService.clearCatalog();
    var requests = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('list.json')) {
        return http.Response('[{"name":"gcc-13.2.0","language":"C++"}]', 200);
      }
      final body = jsonDecode(request.body) as Map;
      requests++;
      expect(body['save'], isFalse);
      final input = int.parse(body['stdin'] as String);
      return http.Response(
          jsonEncode({'status': '0', 'program_output': '${input * 2}\n'}), 200);
    });
    await tester.pumpWidget(MaterialApp(
        home: CodeRunnerPage(
            prefs: prefs,
            mission: codingMissions.first,
            initialLanguage: StudyLanguage.cpp,
            clientFactory: () => client)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('code-editor')).hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byKey(const ValueKey('code-editor')),
        'int n; cin >> n; cout << n * 2;');
    await tester.scrollUntilVisible(
        find.text('Check all test cases').hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Check all test cases'));
    await tester.pumpAndSettle();
    expect(requests, 3);
    expect(prefs.getStringList('missionCompletions'), ['cpp:double']);
    expect(prefs.getString('codeDraft.cpp'), 'keep my work');
    expect(prefs.getString('codeDraft.cpp.mission.double'), contains('n * 2'));
    await tester.scrollUntilVisible(
        find.text('All green. Nice work!').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('All green. Nice work!'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('code-editor')).hitTestable(), -200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(
        find.byKey(const ValueKey('code-editor')), 'cout << 0;');
    await tester.pump();
    expect(find.text('All green. Nice work!'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Failed test outputs never award mission completion',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    CompilerService.clearCatalog();
    await tester.pumpWidget(MaterialApp(
        home: CodeRunnerPage(
            prefs: prefs,
            mission: codingMissions.first,
            clientFactory: () => MockClient((request) async => request.url.path
                    .endsWith('list.json')
                ? http.Response('[{"name":"gcc-13.2.0","language":"C++"}]', 200)
                : http.Response('{"status":"0","program_output":"0"}', 200)))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Check all test cases').hitTestable(), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Check all test cases'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('missionCompletions'), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Splash has no developer credits', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester
        .pumpWidget(QuizQuest(prefs: await SharedPreferences.getInstance()));
    expect(find.textContaining('Jamal'), findsNothing);
    expect(find.textContaining('Zulkifal'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
  });
}
