import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizquest/quest_motion.dart';

void main() {
  testWidgets('Celebration settles and never blocks controls', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuestCelebration(
      celebrate: true,
      child: TextButton(onPressed: () => taps++, child: const Text('Continue')),
    ))));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
  testWidgets('Reduced motion skips entrance and confetti', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Scaffold(
          body: QuestCelebration(celebrate: true, child: Text('Ready'))),
    )));
    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
