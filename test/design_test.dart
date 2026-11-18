import 'package:lottie/lottie.dart';
import 'package:quizquest/lottie_effects.dart';
import 'dart:async';
import 'package:quizquest/quest_refresh.dart';
import 'package:quizquest/animated_navigation.dart';
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
    for (final effect in QuestAnimation.values) {
      await AssetLottie('assets/animations/${effect.name}.json',
              backgroundLoading: false)
          .load();
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
    await tester.runAsync(() => precacheImage(
        const AssetImage('assets/branding/google_g.png'),
        tester.element(find.byType(CloudLogin))));
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
      'Google sign-in cancellation and launch failure keep email login usable',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: CloudLogin(googleSignIn: () async => false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Could not open your browser. Please try again.'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Could not open your browser. Please try again.'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
    await tester.pumpWidget(MaterialApp(
        home: CloudLogin(
            key: const ValueKey('retry'), googleSignIn: () async => true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.textContaining('If you cancelled'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('If you cancelled'), findsOneWidget);
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
    expect(find.byType(QuestNavigation), findsOneWidget);
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
    expect(tester.takeException(), isNull);
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
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Redesigned lesson mode profile and medals fit a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'language': 'cpp',
      'profileName': 'Zulkifal Khan',
      'profileEmail': 'learner@gmail.com',
      'scores': '{"cpp:hello":3}'
    });
    await tester.pumpWidget(QuizQuest(
        skipOnboarding: true, prefs: await SharedPreferences.getInstance()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue Learning'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/redesign_lesson_phone.png'));
    await tester.scrollUntilVisible(
        find.text('Take the quiz').hitTestable(), 350,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Take the quiz'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/redesign_mode_phone.png'));
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/redesign_profile_phone.png'));
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/redesign_profile_editor_phone.png'));
    expect(find.text('Sounds & feedback'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('App Settings').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('App Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Sounds & feedback').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/redesign_settings_phone.png'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Achievements').hitTestable(), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Achievements'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/redesign_medals_phone.png'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Smart review and explanation panels fit a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'language': 'cpp',
      'scores': '{"cpp:hello":3}',
      'mistakes': ['cpp:hello:0'],
      'mastery': '{"C++ · Your first hello":{"attempts":3,"correct":2}}'
    });
    await tester.pumpWidget(QuizQuest(
        skipOnboarding: true, prefs: await SharedPreferences.getInstance()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smart Review'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/smart_review_phone.png'));
    await tester.tap(find.text('C++ · Your first hello'));
    await tester.pumpAndSettle();
    final q = tester.widget<QuizPage>(find.byType(QuizPage)).questions.first;
    await tester.tap(find.text(q.options[(q.answer + 1) % q.options.length]));
    await tester.pump();
    await tester.scrollUntilVisible(
        find.text('Check answer').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Check answer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Why this is correct').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('CORRECT ANSWER'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Modern mission list studio and lesson sandbox fit a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(
        {'language': 'cpp', 'codeDraft.cpp': 'keep original'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(QuizQuest(skipOnboarding: true, prefs: prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue Learning'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Try this code').hitTestable(), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Try this code'));
    await tester.pumpAndSettle();
    final editor = tester.widget<TextField>(find.byType(TextField).first);
    expect(editor.controller!.text, contains('Hello!'));
    expect(prefs.getString('codeDraft.cpp'), 'keep original');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coding Missions'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/coding_missions_phone.png'));
    await tester.tap(find.text('Double trouble'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/mission_studio_phone.png'));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('code-editor')).hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/mission_editor_phone.png'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Mascot refresh header fits the phone layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<void>();
    final key = GlobalKey<QuestPullRefreshState>();
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            appBar: AppBar(title: const Text('LearnCodz')),
            body: QuestPullRefresh(
                key: key,
                onRefresh: () => pending.future,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      Text('Your learning journey',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      SizedBox(height: 20),
                      Text('Small steps. Keep growing.')
                    ])))));
    final refreshing = key.currentState!.show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/mascot_refresh_phone.png'));
    pending.complete();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await refreshing;
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Bundled animation preview renders and replays on phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
        debugShowCheckedModeBanner: false, home: AnimationPreviewPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/lottie_preview_phone.png'));
    await tester.tap(find.byTooltip('Replay flame'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
