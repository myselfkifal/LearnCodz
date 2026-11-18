import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizquest/lessons.dart';
import 'package:quizquest/question_layout.dart';

void main() {
  test(
      'Each answer position is used once per cycle for different option counts',
      () {
    final layout = QuestionLayout(random: Random(17));
    for (final count in [2, 3, 4, 5]) {
      final question =
          Question('Example', List.generate(count, (i) => '$i'), 0, 'Example');
      int? previous;
      for (var cycle = 0; cycle < 3; cycle++) {
        final positions = <int>{};
        for (var n = 0; n < count; n++) {
          final options = layout.optionsFor(question);
          expect(options, unorderedEquals(List.generate(count, (i) => i)));
          final position = options.indexOf(question.answer);
          expect(position, isNot(previous));
          positions.add(position);
          previous = position;
        }
        expect(positions.length, count);
      }
    }
  });

  test('Code ordering keeps authored line indices', () {
    const question = Question(
        'Arrange lines', ['line B', 'line A'], 0, 'A goes first',
        kind: QuestionKind.order, answerOrder: [1, 0]);
    expect(QuestionLayout().optionsFor(question), [0, 1]);
  });
}
