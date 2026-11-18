import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizquest/main.dart';

void main() {
  testWidgets('Brand draws while initialization is pending, then opens app', (tester) async {
    final pending = Completer<Widget>();
    await tester.pumpWidget(StartupApp(load: () => pending.future));
    expect(find.text('LearnCodz'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('LearnCodz'), findsOneWidget);
    pending.complete(const MaterialApp(home: Text('Ready')));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('LearnCodz'), findsNothing);
  });

  testWidgets('Initialization failure offers a working retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(StartupApp(load: () async {
      if (++attempts == 1) throw StateError('Unavailable');
      return const MaterialApp(home: Text('Ready'));
    }));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
    expect(attempts, 2);
  });
}
