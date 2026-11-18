import 'package:flutter/material.dart';
import 'lessons.dart';
import 'polished_panels.dart';

class ReviewSchedule {
  static const intervals = [1, 3, 7, 14, 30];
  static DateTime day(DateTime time) =>
      DateTime(time.year, time.month, time.day);
  static Map<String, dynamic> update(Map<String, dynamic> previous,
      {required int correct, required int attempts, required DateTime now}) {
    final passed = attempts > 0 && correct / attempts >= .8;
    if (passed && due(previous) != null && !isDue(previous, now)) {
      return {...previous, 'reviewedAt': now.toIso8601String()};
    }
    final old = ((previous['reviewLevel'] as num?)?.toInt() ?? -1)
        .clamp(-1, intervals.length - 1);
    final level = passed ? (old + 1).clamp(0, intervals.length - 1) : 0;
    return {
      ...previous,
      'reviewLevel': level,
      'reviewedAt': now.toIso8601String(),
      'reviewDue': day(now)
          .add(Duration(days: passed ? intervals[level] : 1))
          .toIso8601String()
    };
  }

  static DateTime? due(Map<String, dynamic> stat) =>
      DateTime.tryParse('${stat['reviewDue'] ?? ''}');
  static bool isDue(Map<String, dynamic> stat, DateTime now) =>
      ((stat['attempts'] as num?) ?? 0) > 0 &&
      (due(stat) == null || !day(due(stat)!).isAfter(day(now)));
}

class SmartReviewPage extends StatefulWidget {
  final Map<String, dynamic> mastery;
  final List<Lesson> course;
  final bool Function(int) unlocked;
  final ValueChanged<Lesson> onReview;
  final void Function(Lesson, int)? onSizedReview;
  const SmartReviewPage(
      {super.key,
      required this.mastery,
      required this.course,
      required this.unlocked,
      required this.onReview,
      this.onSizedReview});
  @override
  State<SmartReviewPage> createState() => _SmartReviewPageState();
}

class _SmartReviewPageState extends State<SmartReviewPage> {
  int size = 5;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final studied = widget.course
        .asMap()
        .entries
        .where((entry) =>
            widget.unlocked(entry.key) &&
            (((widget.mastery[entry.value.title] as Map?)?['attempts']
                        as num?) ??
                    0) >
                0)
        .map((e) => e.value)
        .toList();
    Map<String, dynamic> stat(Lesson l) =>
        Map<String, dynamic>.from(widget.mastery[l.title] ?? {});
    final due =
        studied.where((l) => ReviewSchedule.isDue(stat(l), now)).toList();
    final upcoming = studied
        .where((l) => !ReviewSchedule.isDue(stat(l), now))
        .toList()
      ..sort((a, b) =>
          ReviewSchedule.due(stat(a))!.compareTo(ReviewSchedule.due(stat(b))!));
    return Scaffold(
        appBar: AppBar(title: const Text('Smart Review')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  FeatureBanner(
                      eyebrow: 'KEEP WHAT YOU LEARN',
                      title: due.isEmpty
                          ? 'Your memory, growing.'
                          : '${due.length} ${due.length == 1 ? 'topic' : 'topics'} ready for you.',
                      subtitle:
                          'Short, untimed rounds revisit what you have learned. Strong results space reviews farther apart.',
                      icon: Icons.psychology_alt_outlined,
                      color: const Color(0xFF8870CD)),
                  if (widget.onSizedReview != null && due.isNotEmpty) ...[
                    Wrap(spacing: 8, children: [
                      for (final n in [5, 10])
                        ChoiceChip(
                            label: Text(n == 5
                                ? 'Quick · 5 questions'
                                : 'Deep · up to 10'),
                            selected: size == n,
                            onSelected: (_) => setState(() => size = n))
                    ]),
                    const SizedBox(height: 18),
                  ],
                  const Text('Ready to review',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  if (due.isEmpty)
                    ToolkitPanel(title: 'You’re all caught up', children: [
                      Text(studied.isEmpty
                          ? 'Complete a lesson or a topic quiz first. Your review plan starts when you save your answers.'
                          : 'No reviews due today. Keep exploring, or come back when the next topic is ready.')
                    ]),
                  for (final lesson in due)
                    _topic(lesson, stat(lesson), true, now),
                  if (upcoming.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text('Coming up',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    for (final lesson in upcoming)
                      _topic(lesson, stat(lesson), false, now)
                  ],
                  const SizedBox(height: 16),
                  const Text(
                      'Reviews update mastery and mistake practice. They do not award extra XP or change chapter unlocks.',
                      style: TextStyle(
                          color: Colors.black54, fontSize: 12, height: 1.5))
                ]))));
  }

  Widget _topic(
      Lesson lesson, Map<String, dynamic> stat, bool ready, DateTime now) {
    final date = ReviewSchedule.due(stat);
    final inDays = date == null
        ? 0
        : ReviewSchedule.day(date).difference(ReviewSchedule.day(now)).inDays;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
            color: ready ? const Color(0xFFF3EFFB) : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(20),
            child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                leading: Icon(
                    ready ? Icons.refresh_rounded : Icons.schedule_rounded,
                    color: const Color(0xFF8870CD)),
                title: Text(lesson.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                subtitle: Text(
                    ready
                        ? '${lesson.allQuestions.length < size ? lesson.allQuestions.length : size} questions · mistakes first'
                        : 'Ready ${inDays == 1 ? 'tomorrow' : 'in $inDays days'}',
                    style: const TextStyle(fontSize: 12)),
                trailing: ready
                    ? const Icon(Icons.play_circle_fill_rounded,
                        color: Color(0xFF8870CD), size: 30)
                    : null,
                onTap: ready
                    ? () {
                        final callback = widget.onSizedReview;
                        if (callback == null) {
                          widget.onReview(lesson);
                        } else {
                          callback(lesson, size);
                        }
                      }
                    : null)));
  }
}
