import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lessons.dart';
import 'language_courses.dart';
import 'sound_effects.dart';

class LearningData extends ChangeNotifier {
  final SharedPreferences prefs;
  static DateTime lastInput = DateTime.now();
  late Set<String> bookmarks;
  late Map<String, dynamic> mastery;
  late Map<String, dynamic> seconds;
  late int goal;
  String? error;
  LearningData(this.prefs) {
    bookmarks = (prefs.getStringList('bookmarks') ?? []).toSet();
    mastery = decode(prefs.getString('mastery'));
    seconds = decode(prefs.getString('learningSeconds'));
    goal = prefs.getInt('dailyGoal') ?? 5;
  }
  static Map<String, dynamic> decode(String? raw) {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw ?? '{}'));
    } catch (_) {
      return {};
    }
  }

  String get today {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  int get todaySeconds => (seconds[today] as num?)?.toInt() ?? 0;
  void tick() {
    seconds[today] = todaySeconds + 1;
    if (todaySeconds == goal * 60) {
      SoundEffects.instance.play(SoundCue.achievement);
    }
    if (todaySeconds % 15 == 0) save();
    notifyListeners();
  }

  void toggle(String id) {
    if (!bookmarks.add(id)) bookmarks.remove(id);
    notifyListeners();
    save();
  }

  void setGoal(int minutes) {
    goal = minutes;
    notifyListeners();
    save();
  }

  void record(Map<Question, bool> answers) {
    for (final entry in answers.entries) {
      final topic = lessons
              .where((l) => l.allQuestions.contains(entry.key))
              .map((l) => l.title)
              .firstOrNull ??
          (activeLanguage == null
              ? 'Coding lab'
              : '${languageName(activeLanguage!)} · Coding lab');
      final stat = Map<String, dynamic>.from(
          mastery[topic] ?? {'correct': 0, 'attempts': 0});
      stat['attempts'] = (stat['attempts'] as int) + 1;
      if (entry.value) stat['correct'] = (stat['correct'] as int) + 1;
      mastery[topic] = stat;
    }
    notifyListeners();
    save();
  }

  Future<void> save() async {
    try {
      final ok = await Future.wait([
        prefs.setStringList('bookmarks', bookmarks.toList()),
        prefs.setString('mastery', jsonEncode(mastery)),
        prefs.setString('learningSeconds', jsonEncode(seconds)),
        prefs.setInt('dailyGoal', goal)
      ]);
      error = ok.every((v) => v)
          ? null
          : 'Learning settings could not be saved. Please retry.';
    } catch (_) {
      error = 'Learning settings could not be saved. Please retry.';
    }
  }

  void reset() {
    bookmarks.clear();
    mastery.clear();
    seconds.clear();
    goal = 5;
    notifyListeners();
    save();
  }
}
