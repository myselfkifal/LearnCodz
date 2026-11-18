import 'dart:convert';
import 'package:quizquest/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/smart_review.dart';
import 'package:quizquest/learning_data.dart';
import 'package:quizquest/language_courses.dart';
import 'package:quizquest/lessons.dart';
import 'package:quizquest/answer_explanation.dart';

void main() {
  tearDown(() => activeLanguage = null);
  test(
      'Review intervals advance, weak attempts reset, and legacy stats are due',
      () {
    final now = DateTime(2026, 11, 3, 22);
    final first = ReviewSchedule.update({'attempts': 5},
        correct: 4, attempts: 5, now: now);
    expect(ReviewSchedule.due(first), DateTime(2026, 11, 4));
    expect(ReviewSchedule.isDue(first, now), isFalse);
    expect(ReviewSchedule.isDue(first, DateTime(2026, 11, 4, 8)), isTrue);
    final second = ReviewSchedule.update(first,
        correct: 5, attempts: 5, now: DateTime(2026, 11, 4));
    expect(ReviewSchedule.due(second), DateTime(2026, 11, 7));
    final weak = ReviewSchedule.update(second,
        correct: 2, attempts: 5, now: DateTime(2026, 11, 7));
    expect(weak['reviewLevel'], 0);
    expect(ReviewSchedule.due(weak), DateTime(2026, 11, 8));
    expect(ReviewSchedule.isDue({'attempts': 3}, now), isTrue);
    expect(ReviewSchedule.isDue({}, now), isFalse);
  });
  test('Saved attempts create one schedule per topic and survive restart',
      () async {
    SharedPreferences.setMockInitialValues({});
    activeLanguage = StudyLanguage.cpp;
    final prefs = await SharedPreferences.getInstance();
    final data = LearningData(prefs);
    final lesson = lessons.first;
    data.record({for (final q in lesson.questions) q: true});
    await data.save();
    final restored = LearningData(prefs);
    expect(restored.mastery[lesson.title]['attempts'], 3);
    expect(restored.mastery[lesson.title]['reviewLevel'], 0);
    expect(restored.mastery[lesson.title]['reviewDue'], isNotNull);
    data.dispose();
    restored.dispose();
  });
  testWidgets(
      'Wrong-answer feedback compares the selected answer with the rule',
      (tester) async {
    const q = Question('What is 5 % 2?', ['0', '1'], 1,
        'The remainder after dividing 5 by 2 is 1.');
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: AnswerExplanation(
                question: q, selected: 0, order: [], timedOut: false))));
    expect(find.text('YOUR ANSWER'), findsOneWidget);
    expect(find.text('CORRECT ANSWER'), findsOneWidget);
    expect(find.text('Why this is correct'), findsOneWidget);
    expect(find.text(q.explanation), findsOneWidget);
  });
  testWidgets('Review queue only offers studied, unlocked topics',
      (tester) async {
    activeLanguage = StudyLanguage.cpp;
    Lesson? chosen;
    final course = lessons;
    await tester.pumpWidget(MaterialApp(
        home: SmartReviewPage(
            course: course,
            mastery: {
              course[0].title: {'attempts': 3},
              course[1].title: {'attempts': 3}
            },
            unlocked: (i) => i == 0,
            onReview: (l) => chosen = l)));
    await tester.pumpAndSettle();
    expect(find.text(course[1].title), findsNothing);
    await tester.tap(find.text(course[0].title));
    expect(chosen, course[0]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Saved review clears mistakes and reschedules without extra XP',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    activeLanguage = StudyLanguage.cpp;
    final lesson = lessons.first;
    SharedPreferences.setMockInitialValues({
      'language': 'cpp',
      'scores': '{"cpp:hello":3}',
      'mistakes': ['cpp:hello:0'],
      'mastery': jsonEncode({
        lesson.title: {
          'attempts': 3,
          'correct': 2,
          'reviewDue': '2020-01-01T00:00:00.000',
          'reviewLevel': 0
        }
      })
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(QuizQuest(skipOnboarding: true, prefs: prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smart Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(lesson.title));
    await tester.pumpAndSettle();
    final quiz = tester.widget<QuizPage>(find.byType(QuizPage));
    expect(quiz.timed, isFalse);
    expect(quiz.questions.first, lesson.questions.first);
    for (var i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      await tester.scrollUntilVisible(
          find.text(q.options[q.answer]).last.hitTestable(), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(q.options[q.answer]).last);
      await tester.pump();
      await tester.scrollUntilVisible(
          find.text('Check answer').hitTestable(), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      final next =
          i == quiz.questions.length - 1 ? 'See my results' : 'Next question';
      await tester.scrollUntilVisible(find.text(next).hitTestable(), 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text(next));
      await tester.pumpAndSettle();
    }
    expect(
        (jsonDecode(prefs.getString('mastery')!) as Map)[lesson.title]
            ['reviewDue'],
        '2020-01-01T00:00:00.000');
    await tester.scrollUntilVisible(
        find.text('Save & continue').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('mistakes'), isEmpty);
    expect(prefs.getString('scores'), '{"cpp:hello":3}');
    expect(prefs.getStringList('quizRewards'), isEmpty);
    final stat =
        (jsonDecode(prefs.getString('mastery')!) as Map)[lesson.title] as Map;
    expect(stat['reviewLevel'], 1);
    expect(DateTime.parse(stat['reviewDue'] as String).isAfter(DateTime.now()),
        isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
