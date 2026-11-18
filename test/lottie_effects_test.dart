import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:quizquest/lottie_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All bundled animations parse without external artwork or fonts',
      () async {
    for (final effect in QuestAnimation.values) {
      final file = File('assets/animations/${effect.name}.json');
      final data = jsonDecode(file.readAsStringSync()) as Map;
      expect(
          (data['assets'] as List)
              .whereType<Map>()
              .where((a) => a['p'] != null),
          isEmpty);
      final composition = await LottieComposition.fromByteData(
          ByteData.sublistView(file.readAsBytesSync()));
      expect(composition.duration.inMilliseconds, greaterThan(0));
      expect(composition.images, isEmpty);
      expect(composition.layers, isNotEmpty);
    }
    expect(File('assets/animations/NOTICE.txt').readAsStringSync(),
        contains('Copyright Google LLC'));
    expect(File('assets/animations/CC-BY-4.0.txt').readAsStringSync(),
        contains('Attribution 4.0 International'));
  });

  testWidgets(
      'Reduced motion shows a static symbol and creates no Lottie ticker',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Scaffold(
          body: QuestLottie(animation: QuestAnimation.flame, repeat: true)),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(LottieBuilder), findsNothing);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('One-shot celebrations are loaded from a local asset',
      (tester) async {
    await tester.runAsync(() => AssetLottie('assets/animations/celebrate.json',
            backgroundLoading: false)
        .load());
    await tester.pumpWidget(const MaterialApp(
        home:
            Scaffold(body: QuestLottie(animation: QuestAnimation.celebrate))));
    await tester.pumpAndSettle();
    final builder = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(builder.lottie, isA<AssetLottie>());
    expect(builder.repeat, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
