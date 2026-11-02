import 'package:flutter/material.dart';
import 'lessons.dart';
import 'quest_motion.dart';

const questGreen = Color(0xFF419500);
const questLime = Color(0xFF6AD51B);
const questBlue = Color(0xFF1CB0F6);
const questText = Color(0xFF111218);

class QuestButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  const QuestButton(
      {super.key, required this.label, this.onPressed, this.color = questLime});
  @override
  Widget build(BuildContext context) => QuestPress(
      child: Container(
          decoration: BoxDecoration(
              gradient: onPressed == null
                  ? null
                  : LinearGradient(
                      colors: [color, Color.lerp(color, Colors.black, .22)!]),
              color: onPressed == null ? const Color(0xFFE7E7EB) : null,
              borderRadius: BorderRadius.circular(16)),
          child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)))));
}

class QuestStats extends StatelessWidget {
  final int xp, streak, completed, total;
  const QuestStats(
      {super.key,
      required this.xp,
      required this.streak,
      required this.completed,
      required this.total});
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 10, runSpacing: 10, children: [
        chip(Icons.local_fire_department_rounded, '$streak day streak',
            const Color(0xFFFF9600)),
        chip(Icons.bolt_rounded, '$xp XP', questBlue),
        chip(Icons.check_circle_rounded, '$completed / $total passed',
            questGreen),
      ]);
  Widget chip(IconData icon, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 13))
      ]));
}

class QuestHero extends StatelessWidget {
  final String title, action;
  final VoidCallback onStart;
  const QuestHero(
      {super.key,
      required this.title,
      required this.action,
      required this.onStart});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFF0FBE7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD7EDC5), width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.school_rounded, color: questGreen),
          SizedBox(width: 8),
          Expanded(
              child: Text('PROGRAMMING FOUNDATIONS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: questGreen)))
        ]),
        const SizedBox(height: 18),
        Text(title,
            style: const TextStyle(
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: questText)),
        const SizedBox(height: 12),
        const Text('Tiny lessons. Real progress.\nMake today a little smarter.',
            style: TextStyle(color: Color(0xFF777777), height: 1.6)),
        const SizedBox(height: 22),
        QuestButton(label: action, onPressed: onStart),
      ]));
}

class QuestPath extends StatelessWidget {
  final Map<String, int> scores;
  final void Function(int) onLesson;
  final bool Function(int) unlocked;
  final String filter;
  const QuestPath(
      {super.key,
      required this.scores,
      required this.onLesson,
      required this.unlocked,
      this.filter = 'All lessons'});
  @override
  Widget build(BuildContext context) {
    final visible = List.generate(lessons.length, (i) => i)
        .where((i) => filter == 'Completed'
            ? (scores[lessons[i].id] ?? 0) >= 2
            : filter == 'Available'
                ? unlocked(i)
                : true)
        .toList();
    if (visible.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
              'Your first win is waiting. Complete a lesson to see it here.'));
    }
    return QuestEntrance(
        key: ValueKey(filter),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Think like a programmer',
              style: TextStyle(fontSize: 13, color: Color(0xFF777780))),
          const SizedBox(height: 18),
          ...visible.expand((i) {
            final l = lessons[i],
                open = unlocked(i),
                passed = (scores[l.id] ?? 0) >= 2,
                current = open && !passed;
            final color = passed
                ? questLime
                : current
                    ? const Color(0xFFDDF5BB)
                    : const Color(0xFFF0F0F3);
            final title = l.id.contains(':')
                ? {
                      'hello': 'Hello World',
                      'variables': 'Variables',
                      'conditions': 'Decision Making',
                      'loops': 'Loops',
                      'functions': 'Functions',
                      'collections': 'Arrays & Lists'
                    }[l.id.split(':').last] ??
                    l.title.split(' · ').last
                : l.title;
            return <Widget>[
              if (i % 6 == 0)
                Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 18, top: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0F9E6),
                        borderRadius: BorderRadius.circular(18)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STAGE ${i ~/ 6 + 1}',
                              style: const TextStyle(
                                  color: questGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(
                              [
                                'Foundations',
                                'Working with Data',
                                'Problem Solving'
                              ][i ~/ 6],
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w800)),
                          Text(
                              '${List.generate(6, (j) => i + j).where((j) => j < lessons.length && (scores[lessons[j].id] ?? 0) >= 2).length} / ${lessons.length - i < 6 ? lessons.length - i : 6} chapters passed',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54))
                        ])),
              SizedBox(
                  height: 86,
                  child: Stack(children: [
                    if (i != visible.last)
                      Positioned(
                          left: 32,
                          top: 48,
                          bottom: 0,
                          child: Container(
                              width: 3,
                              color: passed
                                  ? questLime
                                  : const Color(0xFFE6E6EB))),
                    Tooltip(
                        message: l.title,
                        child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: open ? () => onLesson(i) : null,
                                child: Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: Row(children: [
                                      Container(
                                          width: 66,
                                          height: 62,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: color,
                                              border: Border.all(
                                                  color: current
                                                      ? questGreen
                                                      : passed
                                                          ? questLime
                                                          : const Color(
                                                              0xFFE3E3E8),
                                                  width: current ? 3 : 2)),
                                          child: Icon(
                                              current
                                                  ? Icons
                                                      .play_circle_filled_rounded
                                                  : l.icon,
                                              color: passed
                                                  ? Colors.white
                                                  : current
                                                      ? questGreen
                                                      : const Color(0xFF96969E),
                                              size: 29)),
                                      const SizedBox(width: 18),
                                      Expanded(
                                          child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                      horizontal: 8),
                                              decoration: BoxDecoration(
                                                  color: current
                                                      ? const Color(0xFFF2FAE9)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          22)),
                                              child: Text(title,
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: open
                                                          ? FontWeight.w800
                                                          : FontWeight.w500,
                                                      color: open
                                                          ? questText
                                                          : const Color(
                                                              0xFF85858D))))),
                                      const SizedBox(width: 8),
                                      if (passed)
                                        const Icon(Icons.check_circle,
                                            color: questGreen, size: 19)
                                      else if (!open)
                                        const Icon(Icons.lock_rounded,
                                            color: Color(0xFF9C9CA4), size: 19)
                                    ])))))
                  ]))
            ];
          })
        ]));
  }
}
