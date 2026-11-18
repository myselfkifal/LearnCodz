import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/main.dart';
import 'package:quizquest/lessons.dart';
import 'package:quizquest/language_courses.dart';
import 'package:quizquest/welcome_profile.dart';
import 'package:quizquest/coding_questions.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
      'monospace': 'roboto-regular.ttf'
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(File('test/fonts/${entry.value}')
            .readAsBytes()
            .then(ByteData.sublistView));
      await loader.load();
    }
  });
  tearDown(() => activeLanguage = null);
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('Every language has basics, challenges, stable IDs and a coding lab',
      () {
    final ids = <String>{};
    for (final l in StudyLanguage.values) {
      final course = languageCourses[l]!;
      expect(course.length, 18);
      expect(languageLabs[l]!.length, 8);
      for (final lesson in course) {
        expect(ids.add(lesson.id), isTrue);
        expect(lesson.questions.length, 3);
        expect(lesson.challengeQuestions.length, 3);
        expect(lesson.practiceQuestions.length, 4);
        expect(lesson.allQuestions.length, 10);
        for (final q in lesson.allQuestions) {
          expect(q.answer, inInclusiveRange(0, q.options.length - 1));
        }
      }
    }
    expect(languageCourses[StudyLanguage.c]![5].sections[1].$2,
        contains('undefined behavior'));
    expect(
        languageCourses[StudyLanguage.python]!.first.code, startsWith('print'));
  });
  test('Coding mistake keys do not overlap between languages', () {
    activeLanguage = StudyLanguage.python;
    final key = codingQuestionKey(codingQuestions[1]);
    activeLanguage = StudyLanguage.c;
    expect(codingQuestionKey(codingQuestions[1]), isNot(key));
  });
  testWidgets('Easy and Difficult settings persist the chosen pacing',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    QuizPreferences? chosen;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      chosen = await chooseQuizPreferences(context, prefs);
                    },
                    child: const Text('Modes'))))));
    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Difficult'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto-next after 5 seconds'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quest'));
    await tester.pumpAndSettle();
    expect(chosen?.challenge, isTrue);
    expect(chosen?.autoAdvance, isFalse);
    expect(prefs.getBool('challengeMode'), isTrue);
  });
  testWidgets(
      'Animated startup asks language and switching preserves saved scores',
      (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({'scores': '{"python:hello":2}'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(QuizQuest(prefs: prefs));
    expect(find.text('LearnCodz'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, future coder!'), findsOneWidget);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/language_welcome_phone.png'));
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text("Let's learn Python").hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text("Let's learn Python"));
    await tester.pumpAndSettle();
    expect(prefs.getString('language'), 'python');
    await tester.scrollUntilVisible(
        find.text('Python · Switch').hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Python · Switch'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('C').last.hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('C').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text("Let's learn C").hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text("Let's learn C"));
    await tester.pumpAndSettle();
    expect(prefs.getString('language'), 'c');
    expect(prefs.getString('scores'), '{"python:hello":2}');
    expect(activeLanguage, StudyLanguage.c);
  });
  testWidgets('Name Gmail and buddy save locally with validation',
      (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: ProfilePage(prefs: prefs)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ayesha');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-address');
    await tester.scrollUntilVisible(
        find.text('Save my profile').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save my profile'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid @gmail.com address.'), findsOneWidget);
    await tester.enterText(
        find.byType(TextFormField).at(1), 'ayesha@gmail.com');
    await tester.ensureVisible(find.text('Save my profile'));
    await tester.tap(find.text('Save my profile'));
    await tester.pumpAndSettle();
    expect(prefs.getString('profileName'), 'Ayesha');
    expect(prefs.getString('profileEmail'), 'ayesha@gmail.com');
  });
  testWidgets('Auto-next waits five seconds and can be paused', (tester) async {
    final questions = dartLessons.first.questions.take(2).toList();
    await tester.pumpWidget(MaterialApp(
        home: QuizPage(
            title: 'Auto test', questions: questions, autoAdvance: true)));
    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.ensureVisible(find.text('Check answer'));
    await tester.tap(find.text('Check answer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('QUESTION 1 OF 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause auto-next'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 8));
    expect(find.text('QUESTION 1 OF 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Enable auto-next'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('QUESTION 2 OF 2'), findsOneWidget);
  });
}
