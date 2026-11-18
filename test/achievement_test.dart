import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/achievement_room.dart';
import 'package:quizquest/main.dart';
import 'package:quizquest/language_courses.dart';

void main() {
  tearDown(() => activeLanguage = null);
  test('Medals derive from saved progress and preserve a historical streak',
      () async {
    SharedPreferences.setMockInitialValues({
      'scores': '{"cpp:hello":3,"python:hello":2}',
      'days': ['2026-10-01', '2026-10-02', '2026-10-03'],
      'quizRewards': List.generate(10, (i) => 'cpp:hello:$i'),
      'learningSeconds': '{"2026-10-01":1800}',
    });
    final medals = achievementsFor(await SharedPreferences.getInstance());
    expect(medals.length, 22);
    for (final title in [
      'First Code',
      'Perfect Landing',
      'On a Roll',
      'Arcade Rookie',
      'Focused Mind',
      'Language Hopper'
    ]) {
      expect(medals.singleWhere((a) => a.title == title).earned, isTrue,
          reason: title);
    }
    expect(
        medals.singleWhere((a) => a.title == 'Week Warrior').earned, isFalse);
    expect(medals.singleWhere((a) => a.title == 'XP Legend').progress,
        lessThan(1));
  });
  testWidgets('Phone navigation opens medals and profile editing separately',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'language': 'cpp',
      'profileName': 'Zulkifal Khan',
      'profileEmail': 'learner@gmail.com'
    });
    await tester.pumpWidget(QuizQuest(
        skipOnboarding: true, prefs: await SharedPreferences.getInstance()));
    await tester.pumpAndSettle();
    expect(find.text('Hi, Zulkifal Khan'), findsOneWidget);
    expect(find.text('Edit Profile'), findsNothing);
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('Achievements').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Achievements'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 22 medals unlocked. Every step counts.'),
        findsOneWidget);
    await tester.tap(find.text('Unlocked'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your first medal is waiting.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
