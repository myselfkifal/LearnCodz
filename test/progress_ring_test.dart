import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizquest/reference_design.dart';

void main() {
  testWidgets('Ring counts from zero to saved progress and restarts on reentry', (tester) async {
    Widget page() => const MaterialApp(home: Scaffold(body: ProgressSummary(passed: 5, total: 18, xp: 310, streak: 2)));
    await tester.pumpWidget(page());
    expect(find.text('0%'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    final value = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).value!;
    expect(value, greaterThan(0));
    expect(value, lessThan(5/18));
    await tester.pumpAndSettle();
    expect(find.text('28%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page());
    expect(find.text('0%'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('28%'), findsOneWidget);
  });
}
