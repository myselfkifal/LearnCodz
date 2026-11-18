import 'package:flutter/material.dart';
import 'lessons.dart';

class AnswerExplanation extends StatelessWidget {
  final Question question;
  final int? selected;
  final List<int> order;
  final bool timedOut;
  const AnswerExplanation(
      {super.key,
      required this.question,
      required this.selected,
      required this.order,
      required this.timedOut});
  @override
  Widget build(BuildContext context) {
    final q = question;
    final correct = !timedOut && selected == q.answer;
    final ordered = q.kind == QuestionKind.order;
    String lines(List<int> indices) => indices
        .where((i) => i >= 0 && i < q.options.length)
        .map((i) => q.options[i])
        .join('\n');
    final chosen = ordered
        ? lines(order)
        : selected != null && selected! >= 0 && selected! < q.options.length
            ? q.options[selected!]
            : null;
    final expected = ordered ? lines(q.answerOrder) : q.options[q.answer];
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: correct ? const Color(0xFFF0F8E7) : const Color(0xFFFFF7EC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: correct
                    ? const Color(0xFFD9EBC5)
                    : const Color(0xFFF3DEC4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(correct ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
                color: correct
                    ? const Color(0xFF419500)
                    : const Color(0xFFD78A21)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    timedOut
                        ? 'Time is up. Here is the idea.'
                        : correct
                            ? 'You got it!'
                            : 'A good moment to learn.',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)))
          ]),
          if (!correct) ...[
            const SizedBox(height: 16),
            if (chosen != null && !timedOut) ...[
              const Text('YOUR ANSWER',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Color(0xFF9C7160),
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(chosen, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12)
            ],
            Text(ordered ? 'CORRECT ORDER' : 'CORRECT ANSWER',
                style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: Color(0xFF508130),
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(expected,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
          const SizedBox(height: 16),
          Text(correct ? 'Why it works' : 'Why this is correct',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text(q.explanation, style: const TextStyle(height: 1.6)),
          if (!correct && q.kind == QuestionKind.output) ...[
            const SizedBox(height: 12),
            const Text(
                'Trace the values one statement at a time, then check what the output statement receives.',
                style: TextStyle(fontSize: 12, color: Colors.black54))
          ],
        ]));
  }
}
