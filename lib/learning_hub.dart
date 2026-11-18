import 'polished_panels.dart';
import 'package:flutter/material.dart';
import 'lessons.dart';
import 'learning_data.dart';
import 'reminders.dart';
import 'quest_widgets.dart';
import 'quest_motion.dart';

class LearningHub extends StatefulWidget {
  final LearningData data;
  final ReminderService reminders;
  final void Function(int) openLesson;
  const LearningHub(
      {super.key,
      required this.data,
      required this.reminders,
      required this.openLesson});
  @override
  State<LearningHub> createState() => _LearningHubState();
}

class _LearningHubState extends State<LearningHub> with WidgetsBindingObserver {
  bool busy = false;
  String? message;
  String notificationStatus = 'Checking notification permission...';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy) {
      resumeReminders();
    }
  }

  Future<void> resumeReminders() async {
    final prefs = widget.data.prefs;
    if (prefs.getBool('reminders') ?? false) {
      try {
        await widget.reminders.configure(
            true,
            prefs.getInt('reminderHour') ?? 19,
            prefs.getInt('reminderMinute') ?? 0,
            request: false);
      } catch (_) {}
    }
    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    try {
      final result = await widget.reminders.status();
      if (mounted) setState(() => notificationStatus = result);
    } catch (_) {
      if (mounted) {
        setState(() => notificationStatus =
            'Notification status unavailable. Use the test button on your Android phone.');
      }
    }
  }

  Future<void> testNotification() async {
    setState(() => busy = true);
    try {
      final ok = await widget.reminders.test();
      if (mounted) {
        setState(() => message = ok
            ? 'Test sent. Check the notification shade and sound settings.'
            : 'Permission was not granted. Open notification settings and allow LearnCodz.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => message =
            'The test could not be sent. Check notification settings and try again.');
      }
    }
    await refreshStatus();
    if (mounted) setState(() => busy = false);
  }

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
    await refreshStatus();
    if (mounted) setState(() => busy = false);
  }

  Widget section(String title, List<Widget> children) =>
      ToolkitPanel(title: title, children: children);
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
                    return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const FeatureBanner(
                              eyebrow: 'YOUR LEARNING SPACE',
                              title: 'Build your rhythm.',
                              subtitle:
                                  'A little focus, a saved idea, a new skill. Make learning yours.',
                              icon: Icons.auto_awesome_rounded),
                          section('Your daily mission', [
                            Text(
                                '${data.todaySeconds ~/ 60}m ${data.todaySeconds % 60}s of ${data.goal} minutes today'),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                                value: (data.todaySeconds / (data.goal * 60))
                                    .clamp(0, 1),
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(10)),
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
                                : 'Your active learning time counts toward this goal.'),
                            const Tooltip(
                                message:
                                    'Study time counts while LearnCodz is visible and you have tapped or scrolled within the last minute.',
                                child: Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.info_outline,
                                              size: 16, color: Colors.black54),
                                          SizedBox(width: 6),
                                          Text('How time is counted',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54))
                                        ]))),
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
                          section('Your learning nudge', [
                            const Text(ReminderService.description),
                            const SizedBox(height: 8),
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
                            ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text('Having trouble?'),
                                children: [
                                  Text(notificationStatus),
                                  Wrap(spacing: 8, children: [
                                    OutlinedButton.icon(
                                        onPressed:
                                            busy ? null : testNotification,
                                        icon: const Icon(Icons
                                            .notifications_active_outlined),
                                        label: const Text(
                                            'Send test notification')),
                                    TextButton(
                                        onPressed: busy
                                            ? null
                                            : () async {
                                                final opened = await widget
                                                    .reminders
                                                    .openSettings();
                                                if (!opened && mounted) {
                                                  setState(() => message =
                                                      'Open your device or browser notification settings and allow LearnCodz.');
                                                }
                                              },
                                        child: const Text(
                                            'Notification settings')),
                                    TextButton(
                                        onPressed: busy ? null : refreshStatus,
                                        child: const Text('Refresh status')),
                                  ]),
                                ]),
                            if (message != null) Text(message!)
                          ]),
                        ]);
                  }))));
}
