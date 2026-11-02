import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quizquest/learning_data.dart';
import 'package:quizquest/lessons.dart';
import 'package:quizquest/coding_questions.dart';
import 'package:quizquest/main.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('Roboto')
      ..addFont(File('test/fonts/roboto-regular.ttf')
          .readAsBytes()
          .then(ByteData.sublistView));
    final icons = FontLoader('MaterialIcons')
      ..addFont(File('test/fonts/materialicons-regular.otf')
          .readAsBytes()
          .then(ByteData.sublistView));
    final codeFont = FontLoader('monospace')
      ..addFont(File('test/fonts/roboto-regular.ttf')
          .readAsBytes()
          .then(ByteData.sublistView));
    await codeFont.load();
    await font.load();
    await icons.load();
  });
  test('Bookmarks goals study time and mastery survive reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final data = LearningData(prefs);
    data.toggle('variables');
    data.setGoal(10);
    for (var i = 0; i < 65; i++) {
      data.tick();
    }
    data.record({
      lessons.first.questions.first: true,
      lessons.first.questions[1]: false
    });
    await data.save();
    final restored = LearningData(prefs);
    expect(restored.bookmarks, {'variables'});
    expect(restored.goal, 10);
    expect(restored.todaySeconds, 65);
    expect(
        restored.mastery['Meet your variables'], {'correct': 1, 'attempts': 2});
    restored.reset();
    await restored.save();
    expect(LearningData(prefs).bookmarks, isEmpty);
  });
  testWidgets('Arrange code checks the actual line order', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final q = codingQuestions[2];
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xFF58A700))),
        home: QuizPage(title: 'Arrange', questions: [q], labMode: true)));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/code_shuffle_phone.png'));
    await tester.ensureVisible(find.byTooltip('Move line up').at(1));
    await tester.tap(find.byTooltip('Move line up').at(1));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Move line up').at(2));
    await tester.tap(find.byTooltip('Move line up').at(2));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Check answer').hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Check answer'));
    await tester.pumpAndSettle();
    expect(find.text('You got it!'), findsOneWidget);
  });
  test('Interactive bank contains each promised question type', () {
    expect(codingQuestions.map((q) => q.kind).toSet(), {
      QuestionKind.output,
      QuestionKind.blank,
      QuestionKind.order,
      QuestionKind.bug
    });
    for (final q
        in codingQuestions.where((q) => q.kind == QuestionKind.order)) {
      expect(q.answerOrder.toSet(),
          List.generate(q.options.length, (i) => i).toSet());
    }
  });
}
