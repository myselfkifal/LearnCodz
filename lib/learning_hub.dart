import 'package:flutter/material.dart';
import 'lessons.dart';
import 'learning_data.dart';
import 'reminders.dart';
import 'quest_widgets.dart';
import 'quest_motion.dart';
import 'language_courses.dart';

class LearningHub extends StatefulWidget {
  final LearningData data;
  final ReminderService reminders;
  final void Function(int) openLesson;
  final VoidCallback openLab;
  const LearningHub(
      {super.key,
      required this.data,
      required this.reminders,
      required this.openLesson,
      required this.openLab});
  @override
  State<LearningHub> createState() => _LearningHubState();
}

class _LearningHubState extends State<LearningHub> {
  bool busy = false;
  String? message;
  Future<void> reminder(bool enable) async {
    final prefs = widget.data.prefs;
    var hour = prefs.getInt('reminderHour') ?? 19,
        minute = prefs.getInt('reminderMinute') ?? 0;
    if (enable) {
      final time = await showTimePicker(
          context: context, initialTime: TimeOfDay(hour: hour, minute: minute));
      if (time == null || !mounted) return;
      hour = time.hour;
      minute = time.minute;
    }
    setState(() => busy = true);
    try {
      final ok = await widget.reminders.configure(enable, hour, minute);
      if (ok) {
        final saved = await Future.wait([
          prefs.setBool('reminders', enable),
          prefs.setInt('reminderHour', hour),
          prefs.setInt('reminderMinute', minute)
        ]);
        if (saved.any((v) => !v)) throw StateError('Storage unavailable');
      }
      if (mounted) {
        setState(() => message = ok
            ? enable
                ? 'Reminder enabled at ${TimeOfDay(hour: hour, minute: minute).format(context)}.'
                : 'Reminders turned off.'
            : 'Notifications were not allowed. Enable permission in your device or browser settings, then retry.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => message =
            'Could not configure the reminder on this device. Please retry.');
      }
    }
    if (mounted) setState(() => busy = false);
  }

  Widget section(String title, List<Widget> children) => Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        ...children
      ]));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Your learning toolkit')),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: AnimatedBuilder(
                  animation: widget.data,
                  builder: (context, _) {
                    final data = widget.data;
                    final saved = lessons
                        .asMap()
                        .entries
                        .where((e) => data.bookmarks.contains(e.value.id))
                        .toList();
                    final topics = [
                      ...lessons.map((l) => l.title),
                      activeLanguage == null
                          ? 'Coding lab'
                          : '${languageName(activeLanguage!)} · Coding lab'
                    ];
                    return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          section('Make code click', [
                            const Text(
                                'Predict output, fill missing code, arrange lines, and find bugs. Eight hands-on questions, with explanations and no timer.'),
                            const SizedBox(height: 16),
                            QuestButton(
                                label: 'Open coding lab',
                                onPressed: widget.openLab,
                                color: questBlue)
                          ]),
                          section('Your daily mission', [
                            Text(
                                '${data.todaySeconds ~/ 60}m ${data.todaySeconds % 60}s of ${data.goal} minutes today'),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                                value: (data.todaySeconds / (data.goal * 60))
                                    .clamp(0, 1),
                                minHeight: 10),
                            const SizedBox(height: 12),
                            Wrap(
                                spacing: 8,
                                children: [5, 10, 15]
                                    .map((n) => ChoiceChip(
                                        label: Text('$n minutes'),
                                        selected: data.goal == n,
                                        onSelected: (_) => data.setGoal(n)))
                                    .toList()),
                            const SizedBox(height: 8),
                            if (data.todaySeconds >= data.goal * 60)
                              const QuestCelebration(
                                  celebrate: true,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14),
                                      child: Row(children: [
                                        Icon(Icons.emoji_events_rounded,
                                            color: Color(0xFFFFC800), size: 36),
                                        SizedBox(width: 12),
                                        Expanded(
                                            child: Text(
                                                'Mission complete! A small win worth celebrating.',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: questGreen)))
                                      ]))),
                            Text(data.todaySeconds >= data.goal * 60
                                ? 'Daily goal reached. Great work!'
                                : 'Time counts while the app is visible and you have interacted in the last minute. Tap or scroll to keep learning.'),
                            if (data.error != null)
                              Text(data.error!,
                                  style: const TextStyle(color: Colors.red))
                          ]),
                          section('Your pocket library', [
                            const Text(
                                'Use the bookmark icon in any lesson to save it here.'),
                            const SizedBox(height: 8),
                            if (saved.isEmpty)
                              const Text(
                                  'No bookmarks yet. Start with a lesson you want to revisit.'),
                            ...saved.map((e) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(e.value.title),
                                leading: const Icon(Icons.bookmark,
                                    color: questGreen),
                                onTap: () => widget.openLesson(e.key),
                                trailing: IconButton(
                                    tooltip: 'Remove bookmark',
                                    icon: const Icon(Icons.close),
                                    onPressed: () => data.toggle(e.value.id))))
                          ]),
                          section('Your skill map', [
                            const Text(
                                'Accuracy across all saved attempts, including mistake practice. More attempts give a clearer picture.'),
                            const SizedBox(height: 14),
                            ...topics.map((topic) {
                              final stat = Map<String, dynamic>.from(
                                  data.mastery[topic] ?? {});
                              final attempts =
                                      (stat['attempts'] as num?)?.toInt() ?? 0,
                                  correct =
                                      (stat['correct'] as num?)?.toInt() ?? 0;
                              final rate =
                                  attempts == 0 ? 0.0 : correct / attempts;
                              return Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(topic,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                            value: rate.clamp(0, 1),
                                            minHeight: 7,
                                            color: rate >= .8
                                                ? questLime
                                                : questBlue),
                                        const SizedBox(height: 5),
                                        Text(
                                            attempts == 0
                                                ? 'Unexplored territory. Your first try starts the journey.'
                                                : '$correct / $attempts correct · ${(rate * 100).round()}% · ${attempts < 3 ? 'Keep exploring' : rate >= .8 ? 'Skill shining!' : 'Your next growth opportunity'}',
                                            style:
                                                const TextStyle(fontSize: 12))
                                      ]));
                            })
                          ]),
                          section('Your learning nudge', [
                            const Text(ReminderService.description),
                            const SizedBox(height: 12),
                            SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Daily reminder'),
                                value: data.prefs.getBool('reminders') ?? false,
                                onChanged: busy ? null : reminder),
                            if (data.prefs.getBool('reminders') ?? false)
                              TextButton(
                                  onPressed: busy ? null : () => reminder(true),
                                  child: const Text('Change reminder time')),
                            if (message != null) Text(message!)
                          ]),
                        ]);
                  }))));
}
