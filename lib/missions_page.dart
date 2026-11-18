import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coding_missions.dart';
import 'code_runner.dart';
import 'language_courses.dart';
import 'polished_panels.dart';

class MissionsPage extends StatefulWidget {
  final SharedPreferences prefs;
  const MissionsPage({super.key, required this.prefs});
  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  late StudyLanguage language = activeLanguage ?? StudyLanguage.cpp;
  @override
  Widget build(BuildContext context) {
    final completed = widget.prefs.getStringList('missionCompletions') ?? [];
    return Scaffold(
        appBar: AppBar(title: const Text('Coding Missions')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  const FeatureBanner(
                      eyebrow: 'BUILD SOMETHING REAL',
                      title: 'From idea to “it works”.',
                      subtitle:
                          'A small brief. A few hints. Three test cases to prove your code works.',
                      icon: Icons.rocket_launch_rounded,
                      color: Color(0xFF288CB3)),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: StudyLanguage.values
                          .map((l) => ChoiceChip(
                              label: Text(languageName(l)),
                              selected: language == l,
                              onSelected: (_) => setState(() => language = l)))
                          .toList()),
                  const SizedBox(height: 22),
                  for (final entry in codingMissions.indexed)
                    Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2EBF1))),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => CodeRunnerPage(
                                          prefs: widget.prefs,
                                          initialLanguage: language,
                                          mission: entry.$2)));
                              if (mounted) setState(() {});
                            },
                            child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFEAF6FB),
                                                borderRadius:
                                                    BorderRadius.circular(15)),
                                            child: Icon(
                                                [
                                                  Icons.bolt_rounded,
                                                  Icons.school_outlined,
                                                  Icons.search_rounded
                                                ][entry.$1 % 3],
                                                color: const Color(0xFF288CB3),
                                                size: 28)),
                                        const Spacer(),
                                        if (completed.contains(
                                            '${language.name}:${entry.$2.id}'))
                                          const Chip(
                                              avatar: Icon(Icons.check_circle,
                                                  color: Color(0xFF419500),
                                                  size: 16),
                                              label: Text('Completed'))
                                        else
                                          const Text('3 STEPS · 3 TESTS',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w800))
                                      ]),
                                      const SizedBox(height: 16),
                                      Text(entry.$2.title,
                                          style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 8),
                                      Text(entry.$2.description,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                              color: Colors.black54)),
                                      const SizedBox(height: 16),
                                      Row(children: [
                                        Text(
                                            'Build in ${languageName(language)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF288CB3))),
                                        const Spacer(),
                                        const Icon(Icons.arrow_forward_rounded,
                                            color: Color(0xFF288CB3))
                                      ])
                                    ]))))
                ]))));
  }
}
