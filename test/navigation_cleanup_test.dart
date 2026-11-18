import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/main.dart';
import 'package:quizquest/reference_design.dart';
import 'package:quizquest/language_courses.dart';

void main() {
  tearDown(() => activeLanguage = null);
  testWidgets(
      'Settings owns reset and sound controls; profile and overview stay focused',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'language': 'cpp',
      'profileName': 'Zulkifal Khan',
      'profileEmail': 'learner@gmail.com',
      'scores': '{"cpp:hello":3}',
      'quizRewards': ['cpp:hello:0'],
      'bookmarks': ['cpp:hello'],
      'mastery': '{"C++ · Your first hello":{"attempts":3,"correct":3}}'
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(QuizQuest(skipOnboarding: true, prefs: prefs));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Complete today’s challenge').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Daily Challenge'), findsNothing);
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Reset my progress'), findsNothing);
    expect(find.text('Open learning toolkit'), findsNothing);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressSummary), findsOneWidget);
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Sounds & feedback'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('App Settings').hitTestable(), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('App Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Sounds & feedback'), findsOneWidget);
    expect(find.text('Save my profile'), findsNothing);
    await tester.scrollUntilVisible(
        find.text('Reset my progress').hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Reset my progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep progress'));
    await tester.pumpAndSettle();
    expect(prefs.getString('scores'), '{"cpp:hello":3}');
    await tester.tap(find.text('Reset my progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset').last);
    await tester.pumpAndSettle();
    expect(prefs.getString('scores'), '{}');
    expect(prefs.getStringList('quizRewards'), isEmpty);
    expect(prefs.getString('mastery'), '{}');
    expect(prefs.getStringList('bookmarks'), isEmpty);
    expect(prefs.getString('profileName'), 'Zulkifal Khan');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
