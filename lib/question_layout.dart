import 'dart:math';
import 'lessons.dart';

/// Balances correct positions without changing the stored option indices.
class QuestionLayout {
  final Random random;
  final Map<int, List<int>> _positions = {};
  final Map<int, int> _last = {};
  QuestionLayout({Random? random}) : random = random ?? Random();

  List<int> optionsFor(Question question) {
    final count = question.options.length;
    final indices = List.generate(count, (i) => i);
    if (question.kind == QuestionKind.order || count < 2) return indices;
    final positions = _positions.putIfAbsent(count, () => []);
    if (positions.isEmpty) {
      positions.addAll(indices..shuffle(random));
      if (positions.last == _last[count]) {
        final first = positions.first;
        positions[0] = positions.last;
        positions[positions.length - 1] = first;
      }
    }
    final correctPosition = positions.removeLast();
    _last[count] = correctPosition;
    return indices
      ..remove(question.answer)
      ..shuffle(random)
      ..insert(correctPosition, question.answer);
  }
}
