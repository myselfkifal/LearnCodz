import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizquest/animated_navigation.dart';
import 'package:quizquest/quest_refresh.dart';

void main() {
  testWidgets('Raised tabs select once and support reduced motion',
      (tester) async {
    var selected = 0;
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: StatefulBuilder(
          builder: (context, update) => Scaffold(
                bottomNavigationBar: QuestNavigation(
                    selectedIndex: selected,
                    labels: const [
                      'Overview',
                      'Learn',
                      'Practice',
                      'Progress',
                      'Profile'
                    ],
                    icons: const [
                      Icons.home,
                      Icons.book,
                      Icons.code,
                      Icons.bar_chart,
                      Icons.person
                    ],
                    onSelected: (value) {
                      taps++;
                      update(() => selected = value);
                    }),
              )),
    )));
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(taps, 1);
    expect(
        tester
            .widget<QuestNavigation>(find.byType(QuestNavigation))
            .selectedIndex,
        2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Refresh shows buddy while work is pending then closes',
      (tester) async {
    final key = GlobalKey<QuestPullRefreshState>();
    final work = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuestPullRefresh(
      key: key,
      onRefresh: () {
        calls++;
        return work.future;
      },
      child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Text('Your lessons')]),
    ))));
    final refreshing = key.currentState!.show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls, 1);
    expect(find.text('Refreshing your journey…'), findsOneWidget);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('mascot-refresh-header')))
            .height,
        greaterThan(0));
    work.complete();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await refreshing;
    expect(
        tester
            .getSize(find.byKey(const ValueKey('mascot-refresh-header')))
            .height,
        0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Taps and small pulls never show the refresh header',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuestPullRefresh(
      onRefresh: () async {
        calls++;
      },
      child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Text('Short page')]),
    ))));
    final target = find.text('Short page');
    final header = find.byKey(const ValueKey('mascot-refresh-header'));
    for (var i = 0; i < 3; i++) {
      await tester.tap(target);
      final gesture = await tester.startGesture(tester.getCenter(target));
      await gesture.moveBy(const Offset(0, 36));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getSize(header).height, 0);
      await gesture.up();
      await tester.pumpAndSettle();
    }
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pulling a short page triggers refresh', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: QuestPullRefresh(
      onRefresh: () async {
        calls++;
      },
      child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Text('Short page')]),
    ))));
    await tester.drag(find.text('Short page'), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });
}
