import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/main.dart';
import 'package:quizquest/lessons.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Roboto');
    loader.addFont(File('test/fonts/roboto-regular.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.sublistView(bytes)));
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(File('test/fonts/materialicons-regular.otf')
        .readAsBytes()
        .then((bytes) => ByteData.sublistView(bytes)));
    await icons.load();
  });
  Future<void> boot(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(QuizQuest(
        skipOnboarding: true, prefs: await SharedPreferences.getInstance()));
    await tester.pumpAndSettle();
  }

  testWidgets('Mobile overview and lesson', (tester) async {
    await boot(tester, const Size(390, 844));
    expect(find.text('LearnCodz'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/overview_phone.png'));
    await tester.scrollUntilVisible(
        find.text('Start: Meet your variables').hitTestable(), 200);
    await tester.tap(find.text('Start: Meet your variables'));
    await tester.pumpAndSettle();
    expect(find.text('A named container'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Lesson path and available filter work', (tester) async {
    await boot(tester, const Size(390, 844));
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Think like a programmer'), findsOneWidget);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/learning_path_phone.png'));
    await tester.tap(find.text('Available'));
    await tester.pumpAndSettle();
    expect(find.text('Meet your variables'), findsOneWidget);
    expect(find.text('Make a decision'), findsNothing);
    await tester.ensureVisible(find.text('Meet your variables'));
    await tester.tap(find
        .descendant(
            of: find.byTooltip('Meet your variables'),
            matching: find.byType(InkWell))
        .first);
    await tester.pumpAndSettle();
    expect(find.text('A named container'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Toolkit opens with coding, goals, bookmarks and mastery',
      (tester) async {
    await boot(tester, const Size(390, 844));
    final button = find.text('Learning toolkit · Goals, bookmarks & coding');
    await tester.scrollUntilVisible(button.hitTestable(), 200);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Make code click'), findsOneWidget);
    expect(find.text('Your daily mission'), findsOneWidget);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/toolkit_phone.png'));
    await tester.tap(find.text('10 minutes'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('dailyGoal'), 10);
    await tester.scrollUntilVisible(find.text('Your skill map'), 250);
    expect(find.text('Your skill map'), findsOneWidget);
  });
  testWidgets('Desktop sidebar', (tester) async {
    await boot(tester, const Size(1366, 950));
    expect(find.text('Learning path'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/overview_desktop.png'));
  });
  testWidgets('Quiz feedback and return score', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<int>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => QuizPage(
                                  title: 'Variables',
                                  questions: lessons.first.questions)));
                    },
                    child: const Text('Open quiz'))))));
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      final q = lessons.first.questions[i];
      await tester.tap(find.text(q.options[q.answer]));
      await tester.pump();
      await tester.scrollUntilVisible(
          find.text('Check answer').hitTestable(), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Check answer'));
      await tester.pump();
      expect(find.text('You got it!'), findsOneWidget);
      final next = find.text(i == 2 ? 'See my results' : 'Next question');
      await tester.scrollUntilVisible(next.hitTestable(), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(find.text('3 / 3'), findsOneWidget);
    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();
    expect(result, 3);
    expect(find.text('Open quiz'), findsOneWidget);
  });
  testWidgets('Stored progress unlocks next chapter', (tester) async {
    SharedPreferences.setMockInitialValues({'scores': '{"variables":3}'});
    await tester.pumpWidget(QuizQuest(
        skipOnboarding: true, prefs: await SharedPreferences.getInstance()));
    await tester.pumpAndSettle();
    expect(find.text('Start: Make a decision'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('60 XP'), 200);
    expect(find.text('60 XP'), findsOneWidget);
  });
  testWidgets('Completing a lesson persists score across app restart',
      (tester) async {
    await boot(tester, const Size(390, 844));
    await tester.scrollUntilVisible(
        find.text('Start: Meet your variables').hitTestable(), 200);
    await tester.tap(find.text('Start: Meet your variables'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Take the quiz'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Take the quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto-next after 5 seconds'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quest'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      final q = lessons.first.questions[i];
      await tester.tap(find.text(q.options[q.answer]));
      await tester.pump();
      await tester.scrollUntilVisible(
          find.text('Check answer').hitTestable(), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Check answer'));
      await tester.pump();
      final next = find.text(i == 2 ? 'See my results' : 'Next question');
      await tester.scrollUntilVisible(next.hitTestable(), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('scores'), '{"variables":3}');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(QuizQuest(skipOnboarding: true, prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.text('Start: Make a decision'), findsOneWidget);
  });
  testWidgets('Practice clears correct answers, retains wrong ones and saves',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'mistakes': ['variables:0', 'variables:1'],
      'scores': '{"variables":2}'
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(QuizQuest(skipOnboarding: true, prefs: prefs));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Practice mistakes (2)').hitTestable(), 250);
    await tester.tap(find.text('Practice mistakes (2)'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      final q = lessons.first.questions[i];
      await tester.tap(find.text(
          q.options[i == 0 ? q.answer : (q.answer + 1) % q.options.length]));
      await tester.pump();
      await tester.scrollUntilVisible(
          find.text('Check answer').hitTestable(), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      final next = find.text(i == 1 ? 'See my results' : 'Next question');
      await tester.scrollUntilVisible(next, 150);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Save & continue'));
    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('mistakes'), ['variables:1']);
    expect(prefs.getString('scores'), '{"variables":2}');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(QuizQuest(skipOnboarding: true, prefs: prefs));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Practice mistakes (1)').hitTestable(), 250);
    expect(find.text('Practice mistakes (1)'), findsOneWidget);
  });
  testWidgets('Wrong answer is reported only when completed attempt is saved',
      (tester) async {
    Map<Question, bool>? recorded;
    await tester.pumpWidget(MaterialApp(
        home: QuizPage(
            title: 'Test',
            questions: [lessons.first.questions.first],
            onComplete: (answers) => recorded = answers)));
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.scrollUntilVisible(
        find.text('Check answer').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Check answer'));
    await tester.pumpAndSettle();
    expect(recorded, isNull);
    await tester.scrollUntilVisible(find.text('See my results'), 150);
    await tester.tap(find.text('See my results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();
    expect(recorded?[lessons.first.questions.first], isFalse);
  });
  testWidgets('Daily timeout gives no answer point', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: QuizPage(
            title: 'Daily',
            questions: [lessons.first.questions.first],
            timed: true)));
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Time is up. Here is the idea.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('See my results'), 200);
    await tester.tap(find.text('See my results'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 1'), findsOneWidget);
  });
}
