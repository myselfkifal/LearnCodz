import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/main.dart';
import 'package:quizquest/cloud_progress.dart';
import 'package:quizquest/language_courses.dart';
import 'package:quizquest/code_runner.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final e in {
      'Roboto': 'roboto-regular.ttf',
      'monospace': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf'
    }.entries) {
      final font = FontLoader(e.key)
        ..addFont(File('test/fonts/${e.value}')
            .readAsBytes()
            .then(ByteData.sublistView));
      await font.load();
    }
  });
  tearDown(() => activeLanguage = null);
  testWidgets('Cloud sign in is readable and validates credentials',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF419500))),
        home: const CloudLogin()));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/cloud_login_phone.png'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Code Playground executes through its client and saves code drafts',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    CompilerService.clearCatalog();
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF419500))),
        home: CodeRunnerPage(
            prefs: prefs,
            clientFactory: () => MockClient((request) async => request.url.path
                    .endsWith('list.json')
                ? http.Response('[{"name":"gcc-13.2.0","language":"C++"}]', 200)
                : http.Response(
                    '{"status":"0","program_output":"42","compiler_error":"","program_error":""}',
                    200)))));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/code_playground_phone.png'));
    await tester.enterText(
        find.byType(TextField).first, 'int n; cin >> n; cout << n * 2;');
    await tester.enterText(find.byType(TextField).at(1), '21');
    await tester.scrollUntilVisible(find.text('Run code').hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Run code'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Program finished').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Program finished'), findsOneWidget);
    expect(prefs.getString('codeInput.cpp'), '21');
    expect(prefs.getString('codeDraft.cpp'), contains('n * 2'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reference layout connects practice progress and profile tabs',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'language': 'cpp',
      'profileName': 'Zulkifal Khan',
      'profileEmail': 'learner@gmail.com',
      'scores': '{"cpp:hello":2}',
      'avatar': 2,
      'autoAdvance': false
    });
    await tester.pumpWidget(QuizQuest(
        skipOnboarding: true, prefs: await SharedPreferences.getInstance()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.byIcon(Icons.account_circle_outlined), findsNothing);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/reference_home_phone.png'));
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/reference_path_phone.png'));
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.text('Predict the Output'), findsOneWidget);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/reference_practice_phone.png'));
    await tester.tap(find.text('Predict the Output'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quest'));
    await tester.pumpAndSettle();
    expect(find.text('QUESTION 1 OF 2'), findsOneWidget);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/reference_quiz_phone.png'));
    await tester.tap(find.byTooltip('Leave quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave quiz').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('6%'), findsOneWidget);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/reference_progress_phone.png'));
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
