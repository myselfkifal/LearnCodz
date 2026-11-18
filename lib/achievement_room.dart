import 'dart:convert';
import 'achievement_badge.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quest_widgets.dart';

class QuestAchievement {
  final String title, description;
  final IconData icon;
  final int value, target;
  final Color color;
  const QuestAchievement(this.title, this.description, this.icon, this.value,
      this.target, this.color);
  bool get earned => value >= target;
  double get progress => (value / target).clamp(0, 1);
}

List<QuestAchievement> achievementsFor(SharedPreferences prefs) {
  Map<String, dynamic> decode(String key) {
    try {
      return Map<String, dynamic>.from(
          jsonDecode(prefs.getString(key) ?? '{}'));
    } catch (_) {
      return {};
    }
  }

  final scores = decode('scores');
  final passed = scores.values.where((v) => v is num && v >= 2).length;
  final perfect = scores.values.where((v) => v == 3).length;
  final rewards = prefs.getStringList('quizRewards')?.length ?? 0;
  final daily = prefs.getStringList('daily')?.length ?? 0;
  final days = (prefs.getStringList('days') ?? []).toSet();
  var best = 0;
  for (final key in days) {
    final date = DateTime.tryParse(key);
    if (date == null) continue;
    var count = 0;
    var d = date;
    while (days.contains(
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')) {
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    if (count > best) best = count;
  }
  final xp = scores.values
          .fold<int>(0, (sum, v) => sum + (v is num ? v.toInt() * 20 : 0)) +
      daily * 30 +
      rewards * 10;
  final seconds = decode('learningSeconds')
      .values
      .fold<int>(0, (sum, v) => sum + (v is num ? v.toInt() : 0));
  final languages = scores.entries
      .where((e) => e.value is num && e.value >= 2 && e.key.contains(':'))
      .map((e) => e.key.split(':').first)
      .toSet()
      .length;
  const gold = Color(0xFFFFB800),
      orange = Color(0xFFFF8A24),
      blue = Color(0xFF2196DC),
      purple = Color(0xFF9764DF);
  return [
    QuestAchievement('First Code', 'Pass your first lesson', Icons.code, passed,
        1, questGreen),
    QuestAchievement('Getting Started', 'Pass 3 lessons', Icons.eco_outlined,
        passed, 3, questGreen),
    QuestAchievement('Foundation Builder', 'Pass 6 lessons',
        Icons.layers_outlined, passed, 6, questGreen),
    QuestAchievement('Path Explorer', 'Pass 12 lessons', Icons.explore_outlined,
        passed, 12, blue),
    QuestAchievement('Code Scholar', 'Pass 18 lessons', Icons.school_outlined,
        passed, 18, purple),
    QuestAchievement('Perfect Landing', 'Get 3 out of 3 in a lesson',
        Icons.verified_outlined, perfect, 1, gold),
    QuestAchievement('Sharp Thinker', 'Perfect 5 lessons',
        Icons.psychology_outlined, perfect, 5, purple),
    QuestAchievement('First Spark', 'Earn 100 XP', Icons.bolt, xp, 100, gold),
    QuestAchievement(
        'Rising Star', 'Earn 250 XP', Icons.star_rounded, xp, 250, gold),
    QuestAchievement('XP Explorer', 'Earn 500 XP', Icons.rocket_launch_outlined,
        xp, 500, blue),
    QuestAchievement(
        'XP Legend', 'Earn 1,000 XP', Icons.workspace_premium, xp, 1000, gold),
    QuestAchievement('Showed Up', 'Learn on one day',
        Icons.local_fire_department, days.length, 1, orange),
    QuestAchievement('On a Roll', 'Build a 3 day streak',
        Icons.local_fire_department, best, 3, orange),
    QuestAchievement('Week Warrior', 'Build a 7 day streak', Icons.whatshot,
        best, 7, orange),
    QuestAchievement('Arcade Rookie', 'Save 10 fresh correct arcade answers',
        Icons.sports_esports, rewards, 10, purple),
    QuestAchievement('Arcade Ace', 'Save 50 fresh correct arcade answers',
        Icons.emoji_events_outlined, rewards, 50, gold),
    QuestAchievement('Daily Challenger', 'Complete a daily challenge',
        Icons.today, daily, 1, blue),
    QuestAchievement('Challenge Champion', 'Complete 7 daily challenges',
        Icons.event_available, daily, 7, blue),
    QuestAchievement(
        'Pocket Library',
        'Bookmark 3 lessons',
        Icons.bookmarks_outlined,
        prefs.getStringList('bookmarks')?.length ?? 0,
        3,
        purple),
    QuestAchievement('Focused Mind', 'Study for 30 minutes in total',
        Icons.timer_outlined, seconds ~/ 60, 30, questGreen),
    QuestAchievement('Language Hopper', 'Pass a lesson in 2 languages',
        Icons.translate, languages, 2, blue),
    QuestAchievement('Polyglot Coder', 'Pass a lesson in all 4 languages',
        Icons.public, languages, 4, purple),
  ];
}

class AchievementMedal extends StatelessWidget {
  final QuestAchievement achievement;
  const AchievementMedal({super.key, required this.achievement});
  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Column(children: [
      Semantics(
          label: '${a.title}, ${a.earned ? 'unlocked' : 'locked'}',
          child: AchievementBadge(
              title: a.title, color: a.color, unlocked: a.earned)),
      const SizedBox(height: 9),
      Text(a.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
    ]);
  }
}

class AchievementRoom extends StatefulWidget {
  final SharedPreferences prefs;
  const AchievementRoom({super.key, required this.prefs});
  @override
  State<AchievementRoom> createState() => _AchievementRoomState();
}

class _AchievementRoomState extends State<AchievementRoom> {
  bool earnedOnly = false;
  @override
  Widget build(BuildContext context) {
    final all = achievementsFor(widget.prefs);
    final earned = all.where((a) => a.earned).length;
    final visible = all.where((a) => !earnedOnly || a.earned).toList();
    return Scaffold(
        appBar: AppBar(title: const Text('Achievements')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Text('Small wins. Big energy.',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                      '$earned of ${all.length} medals unlocked. Every step counts.'),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                      value: earned / all.length,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(10)),
                  const SizedBox(height: 20),
                  Wrap(spacing: 8, children: [
                    ChoiceChip(
                        label: const Text('All medals'),
                        selected: !earnedOnly,
                        onSelected: (_) => setState(() => earnedOnly = false)),
                    ChoiceChip(
                        label: const Text('Unlocked'),
                        selected: earnedOnly,
                        onSelected: (_) => setState(() => earnedOnly = true))
                  ]),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Your first medal is waiting. Pass a lesson to start your collection.')),
                  ...visible.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: a.earned
                              ? a.color.withValues(alpha: .06)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE9E9EF))),
                      child: Row(children: [
                        SizedBox(
                            width: 84, child: AchievementMedal(achievement: a)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(a.description,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                  value: a.progress,
                                  color: a.color,
                                  backgroundColor: const Color(0xFFEAEAF0),
                                  borderRadius: BorderRadius.circular(8)),
                              const SizedBox(height: 7),
                              Text(
                                  a.earned
                                      ? 'Unlocked · nicely done!'
                                      : '${a.value.clamp(0, a.target)} / ${a.target}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: a.earned
                                          ? questGreen
                                          : Colors.black54))
                            ]))
                      ]))),
                ]))));
  }
}

class LessonIllustration extends StatelessWidget {
  final String label;
  const LessonIllustration({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(
      height: 190,
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F9E9),
          borderRadius: BorderRadius.circular(70)),
      child: Stack(alignment: Alignment.center, children: [
        const Positioned(
            left: 20,
            bottom: 20,
            child: Icon(Icons.eco, size: 72, color: Color(0xFF8ACB71))),
        const Positioned(
            right: 20,
            bottom: 24,
            child:
                Icon(Icons.auto_stories, size: 64, color: Color(0xFF9CCB77))),
        Container(
            width: 230,
            height: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF455571),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x22334B76),
                      blurRadius: 12,
                      offset: Offset(0, 8))
                ]),
            child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFF6278A5),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const Text('{ }',
                          style:
                              TextStyle(fontSize: 26, color: Color(0xFFD9E7FF)))
                    ]))),
        Positioned(
            bottom: 16,
            child: Container(
                width: 270,
                height: 8,
                decoration: BoxDecoration(
                    color: const Color(0xFF9CABBF),
                    borderRadius: BorderRadius.circular(10))))
      ]));
}
