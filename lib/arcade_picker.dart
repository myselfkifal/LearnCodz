import 'package:flutter/material.dart';
import 'lessons.dart';
import 'quest_widgets.dart';

class ArcadePicker extends StatefulWidget {
  final bool Function(int) unlocked;
  const ArcadePicker({super.key, required this.unlocked});
  @override
  State<ArcadePicker> createState() => _ArcadePickerState();
}

class _ArcadePickerState extends State<ArcadePicker> {
  int roundSize = 5;
  @override
  Widget build(BuildContext context) => SafeArea(
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0E9FF),
                              borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.sports_esports_rounded,
                              color: Color(0xFF9362E7), size: 30)),
                      const SizedBox(width: 14),
                      const Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Quiz Arcade',
                                style: TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w900)),
                            Text('A little challenge. A fresh win.',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 13))
                          ])),
                      IconButton(
                          tooltip: 'Close arcade',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close))
                    ]),
                    const SizedBox(height: 20),
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E4),
                            borderRadius: BorderRadius.circular(18)),
                        child: const Row(children: [
                          Icon(Icons.bolt_rounded,
                              color: Color(0xFFFFB000), size: 30),
                          SizedBox(width: 10),
                          Expanded(
                              child: Text(
                                  'Earn 10 XP for each first-time correct answer. Save your finished round to claim it.',
                                  style: TextStyle(fontSize: 13, height: 1.5)))
                        ])),
                    const SizedBox(height: 20),
                    const Text('MAKE IT YOUR ROUND',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.black54)),
                    const SizedBox(height: 10),
                    Row(children: [
                      for (final n in [5, 10]) ...[
                        Expanded(
                            child: Semantics(
                                selected: roundSize == n,
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => setState(() => roundSize = n),
                                    child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                            color: roundSize == n
                                                ? const Color(0xFFEDF8E5)
                                                : const Color(0xFFF7F7FA),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: roundSize == n
                                                    ? questGreen
                                                    : const Color(0xFFE8E8EF))),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(children: [
                                                Icon(
                                                    n == 5
                                                        ? Icons.flash_on_rounded
                                                        : Icons
                                                            .rocket_launch_outlined,
                                                    color: questGreen,
                                                    size: 20),
                                                const Spacer(),
                                                Icon(
                                                    roundSize == n
                                                        ? Icons.check_circle
                                                        : Icons.circle_outlined,
                                                    color: roundSize == n
                                                        ? questGreen
                                                        : Colors.grey,
                                                    size: 20)
                                              ]),
                                              const SizedBox(height: 8),
                                              Text('$n questions',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16)),
                                              Text(
                                                  n == 5
                                                      ? 'Quick boost'
                                                      : 'Deep dive',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54))
                                            ]))))),
                        if (n == 5) const SizedBox(width: 12),
                      ]
                    ]),
                    const SizedBox(height: 22),
                    const Text('Choose your topic',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 19)),
                    const SizedBox(height: 12),
                    Expanded(
                        child: ListView.builder(
                            itemCount: lessons.length,
                            itemBuilder: (context, i) {
                              final lesson = lessons[i],
                                  open = widget.unlocked(i);
                              return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                      color: open
                                          ? Colors.white
                                          : const Color(0xFFF8F8FA),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          side: const BorderSide(
                                              color: Color(0xFFE9E9EF))),
                                      child: ListTile(
                                          enabled: open,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18)),
                                          leading: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                  color: open
                                                      ? const Color(0xFFEDF8E5)
                                                      : const Color(0xFFEEEEF2),
                                                  borderRadius:
                                                      BorderRadius.circular(13)),
                                              child: Icon(open ? lesson.icon : Icons.lock_outline, color: open ? questGreen : Colors.grey)),
                                          title: Text(lesson.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: open ? questText : Colors.grey)),
                                          subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(open ? 'Topic quiz · ${lesson.allQuestions.length} questions' : 'Pass the previous chapter to unlock', style: const TextStyle(fontSize: 12))),
                                          trailing: Icon(open ? Icons.arrow_forward_rounded : Icons.lock_outline, color: open ? questGreen : Colors.grey, size: 20),
                                          onTap: open ? () => Navigator.pop(context, (lesson, roundSize)) : null)));
                            }))
                  ]))));
}
