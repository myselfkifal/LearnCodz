import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lessons.dart';
import 'quest_widgets.dart';
import 'quest_motion.dart';
import 'learning_data.dart';
import 'learning_hub.dart';
import 'coding_questions.dart';
import 'reminders.dart';
import 'language_courses.dart';
import 'welcome_profile.dart';
import 'reference_design.dart';
import 'sound_effects.dart';
import 'code_runner.dart';
import 'cloud_progress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const ink = Color(0xFF111218),
    green = Color(0xFF419500),
    mint = Color(0xFFD7FFB8),
    paper = Color(0xFFFFFFFF);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  SoundEffects.instance.initialize(prefs);
  await Supabase.initialize(
    url: 'https://tcxlovxkmnenwfaljfwy.supabase.co',
    publishableKey: 'sb_publishable_ioyjHOdwflJ7YtNc5Fi1lQ_hPiS9U6v',
  );
  final cloud = CloudProgress(prefs, Supabase.instance.client);
  CloudProgress.instance = cloud;
  if (cloud.uid != null) await cloud.prepare();
  runApp(QuizQuest(prefs: prefs, enableCloud: true));
}

class QuizQuest extends StatelessWidget {
  final SharedPreferences prefs;
  final bool skipOnboarding;
  final bool enableCloud;
  const QuizQuest(
      {super.key, required this.prefs, this.skipOnboarding = false, this.enableCloud = false});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'LearnCodz',
      builder: (context, child) => Listener(
          onPointerDown: (_) => LearningData.lastInput = DateTime.now(),
          onPointerSignal: (_) => LearningData.lastInput = DateTime.now(),
          child: child!),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          navigationBarTheme: NavigationBarThemeData(
              iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                  color: states.contains(WidgetState.selected)
                      ? green
                      : const Color(0xFF83838B))),
              labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                  fontSize: 10,
                  fontWeight:
                      states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
                  color: states.contains(WidgetState.selected) ? green : const Color(0xFF62626A)))),
          scaffoldBackgroundColor: paper,
          colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green, surface: Colors.white),
          textTheme: const TextTheme(headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: ink), headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink), titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink), bodyMedium: TextStyle(fontSize: 15, height: 1.6, color: ink)),
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
          cardTheme: CardTheme(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)))),
      home: enableCloud ? CloudGate(child: () => LaunchScreen(prefs: prefs, dashboard: () => Dashboard(prefs: prefs))) : skipOnboarding ? Dashboard(prefs: prefs) : LaunchScreen(prefs: prefs, dashboard: () => Dashboard(prefs: prefs)));
}

String dayKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

class Dashboard extends StatefulWidget {
  final SharedPreferences prefs;
  const Dashboard({super.key, required this.prefs});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  late LearningData learning;
  final reminders = ReminderService();
  Timer? learningTimer;
  bool foreground = true;
  int tab = 0;
  String filter = 'All lessons';
  late Map<String, int> scores;
  late Set<String> days, daily, mistakes;
  bool saveFailed = false;
  @override
  void initState() {
    super.initState();
    activeLanguage = parseLanguage(widget.prefs.getString('language'));
    learning = LearningData(widget.prefs);
    WidgetsBinding.instance.addObserver(this);
    learningTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (foreground &&
          DateTime.now().difference(LearningData.lastInput).inSeconds < 60) {
        learning.tick();
      }
    });
    if (widget.prefs.getBool('reminders') ?? false) {
      reminders
          .configure(true, widget.prefs.getInt('reminderHour') ?? 19,
              widget.prefs.getInt('reminderMinute') ?? 0,
              request: false)
          .catchError((_) => false);
    }
    try {
      scores = Map<String, dynamic>.from(
              jsonDecode(widget.prefs.getString('scores') ?? '{}'))
          .map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      scores = {};
    }
    mistakes = (widget.prefs.getStringList('mistakes') ?? []).toSet();
    days = (widget.prefs.getStringList('days') ?? []).toSet();
    daily = (widget.prefs.getStringList('daily') ?? []).toSet();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    SoundEffects.instance.setActive(foreground);
    if (!foreground) {
      learning.save();
      SoundEffects.instance.stop();
    }
  }

  @override
  void dispose() {
    learningTimer?.cancel();
    reminders.dispose();
    learning.save();
    learning.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> profile() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProfilePage(prefs: widget.prefs)));
    if (mounted) setState(() {});
  }

  void switchLanguage() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (pickerContext) => LanguagePicker(
              prefs: widget.prefs,
              switching: true,
              onSelected: (l) {
                setState(() {
                  activeLanguage = l;
                  filter = 'All lessons';
                });
                Navigator.pop(pickerContext);
              })));
  Widget languageBar() => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
                avatar: const Icon(Icons.translate, size: 18),
                label: Text(
                    '${activeLanguage == null ? 'Dart (legacy)' : languageName(activeLanguage!)} · Switch'),
                onPressed: switchLanguage),
            if ((widget.prefs.getString('profileName') ?? '').trim().isEmpty ||
                (widget.prefs.getString('profileEmail') ?? '').trim().isEmpty)
              ActionChip(
                  avatar: const Icon(Icons.account_circle_outlined, size: 18),
                  label: Text(widget.prefs
                              .getString('profileName')
                              ?.trim()
                              .isNotEmpty ==
                          true
                      ? widget.prefs.getString('profileName')!
                      : 'Edit profile'),
                  onPressed: profile),
          ]));
  String get dailyKey =>
      '${activeLanguage?.name ?? 'dart'}:${dayKey(DateTime.now())}';
  void toolkit() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => LearningHub(
              data: learning,
              reminders: reminders,
              openLesson: openLesson,
              openLab: codingLab)));
  Future<void> codingLab([QuestionKind? kind]) async {
    final mode = await chooseQuizPreferences(context, widget.prefs);
    if (mode == null || !mounted) return;
    final result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
            builder: (_) => QuizPage(
                title:
                    '${activeLanguage == null ? 'Dart' : languageName(activeLanguage!)} Coding lab',
                timed: mode.challenge,
                autoAdvance: mode.autoAdvance,
                avatar: widget.prefs.getInt('avatar') ?? 2,
                questions: kind == null
                    ? codingQuestions
                    : codingQuestions.where((q) => q.kind == kind).toList(),
                labMode: true,
                onComplete: recordMistakes)));
    if (result != null && mounted) {
      setState(() => days.add(dayKey(DateTime.now())));
      await persist();
    }
  }

  int get xp => scores.values.fold(0, (a, b) => a + b * 20) + daily.length * 30;
  int get completed => lessons.where((l) => (scores[l.id] ?? 0) >= 2).length;
  int get streak {
    var day = DateTime.now();
    if (!days.contains(dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var n = 0;
    while (days.contains(dayKey(day))) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  bool unlocked(int i) => i == 0 || (scores[lessons[i - 1].id] ?? 0) >= 2;
  Future<void> persist() async {
    try {
      final ok = await Future.wait([
        widget.prefs.setString('scores', jsonEncode(scores)),
        widget.prefs.setStringList('days', days.toList()),
        widget.prefs.setStringList('daily', daily.toList()),
        widget.prefs.setStringList('mistakes', mistakes.toList())
      ]);
      if (ok.any((v) => !v)) throw StateError('Storage unavailable');
      if (mounted) setState(() => saveFailed = false);
    } catch (_) {
      if (mounted) setState(() => saveFailed = true);
    }
  }

  Future<void> openLesson(int i) async {
    if (!unlocked(i)) return;
    final result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
            builder: (_) => LessonPage(
                lesson: lessons[i],
                onComplete: recordMistakes,
                learning: learning)));
    if (result != null && mounted) {
      final firstPass = (scores[lessons[i].id] ?? 0) < 2 && result >= 2;
      if (firstPass) SoundEffects.instance.play(SoundCue.achievement);
      setState(() {
        scores[lessons[i].id] = max(scores[lessons[i].id] ?? 0, result);
        days.add(dayKey(DateTime.now()));
      });
      await persist();
    }
  }

  Future<void> challenge() async {
    final today = dailyKey;
    if (daily.contains(today)) return;
    final pool = lessons
        .asMap()
        .entries
        .where((entry) => unlocked(entry.key))
        .expand((entry) => entry.value.allQuestions)
        .toList()
      ..shuffle(Random(int.parse(dayKey(DateTime.now()).replaceAll('-', ''))));
    final result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
            builder: (_) => QuizPage(
                title: 'Daily challenge',
                dailyChallenge: true,
                autoAdvance: widget.prefs.getBool('autoAdvance') ?? true,
                avatar: widget.prefs.getInt('avatar') ?? 2,
                onComplete: recordMistakes,
                questions: pool.take(5).toList(),
                timed: true)));
    if (result != null && mounted) {
      setState(() {
        daily.add(today);
        days.add(today);
      });
      await persist();
    }
  }

  String questionKey(Question q) {
    for (final lesson in lessons) {
      final index = lesson.allQuestions.indexOf(q);
      if (index >= 0) return '${lesson.id}:$index';
    }
    return codingQuestionKey(q) ?? q.prompt;
  }

  List<Question> get missedQuestions => [
        ...lessons.expand((l) => l.allQuestions),
        ...codingQuestions
      ].where((q) => mistakes.contains(questionKey(q))).toList();
  void recordMistakes(Map<Question, bool> answers) {
    learning.record(answers);
    setState(() {
      for (final entry in answers.entries) {
        if (!entry.value) mistakes.add(questionKey(entry.key));
      }
    });
  }

  Future<void> practice() async {
    final questions = missedQuestions;
    if (questions.isEmpty) return;
    final result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
            builder: (_) => QuizPage(
                  title: 'Practice mistakes',
                  questions: questions,
                  autoAdvance: widget.prefs.getBool('autoAdvance') ?? true,
                  avatar: widget.prefs.getInt('avatar') ?? 2,
                  practiceMode: true,
                  onComplete: (answers) {
                    learning.record(answers);
                    setState(() {
                      for (final entry in answers.entries) {
                        if (entry.value) {
                          mistakes.remove(questionKey(entry.key));
                        }
                      }
                    });
                  },
                )));
    if (result != null && mounted) {
      setState(() => days.add(dayKey(DateTime.now())));
      await persist();
    }
  }

  Widget mistakesCard() {
    final count = missedQuestions.length;
    return Container(
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFFF3EFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4DAFA), width: 2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.psychology_rounded, color: Color(0xFF9069CD)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    count == 0
                        ? 'A fresh start for your mind'
                        : 'Turn mistakes into mastery',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)))
          ]),
          const SizedBox(height: 10),
          Text(count == 0
              ? 'No mistakes to review. Keep learning — every question helps you grow.'
              : '$count ${count == 1 ? 'question needs' : 'questions need'} another look. Practice without a timer, read the explanation, and clear each one with a correct answer.'),
          const SizedBox(height: 14),
          if (count > 0)
            QuestButton(
                label: 'Practice mistakes ($count)',
                color: const Color(0xFF9069CD),
                onPressed: practice)
          else
            const Row(children: [
              Icon(Icons.check_circle_outline, color: green),
              SizedBox(width: 8),
              Expanded(
                  child: Text('All clear. You are ready for your next lesson!',
                      style:
                          TextStyle(color: green, fontWeight: FontWeight.w700)))
            ]),
        ]));
  }

  Widget brand() => const Row(children: [
        CircleAvatar(
            backgroundColor: ink,
            radius: 19,
            child: Icon(Icons.bolt_rounded, color: mint)),
        SizedBox(width: 10),
        Text('LearnCodz',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: ink))
      ]);
  static const navLabels = [
    'Overview',
    'Learn',
    'Practice',
    'Progress',
    'Profile'
  ];
  static const navIcons = [
    Icons.home_rounded,
    Icons.menu_book_outlined,
    Icons.code_rounded,
    Icons.bar_chart_rounded,
    Icons.person_outline
  ];
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final wide = size.maxWidth >= 860;
        return Scaffold(
            body: SafeArea(
                child: Row(children: [
              if (wide)
                Container(
                    width: 215,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        border: Border(
                            right: BorderSide(color: Color(0xFFEEEEF2)))),
                    child: Column(children: [
                      brand(),
                      const SizedBox(height: 40),
                      ...List.generate(
                          5,
                          (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  selected: tab == i,
                                  selectedTileColor: const Color(0xFFF0F8E9),
                                  leading: Icon(navIcons[i]),
                                  title: Text(
                                      i == 1 ? 'Learning path' : navLabels[i]),
                                  onTap: () => setState(() => tab = i)))),
                      const Spacer(),
                      const Text('Zulkifal Khan & Jamal Khan',
                          style: TextStyle(fontSize: 11, color: Colors.black45))
                    ])),
              Expanded(
                  child: tab == 4
                      ? ProfilePage(prefs: widget.prefs)
                      : Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 900),
                              child: ListView(
                                  key: ValueKey('page-$tab'),
                                  padding: EdgeInsets.all(wide ? 32 : 22),
                                  children: [
                                    if (tab == 0) ...[
                                      Row(children: [
                                        Expanded(child: brand()),
                                        const Icon(
                                            Icons.local_fire_department_rounded,
                                            color: Color(0xFFFF7900)),
                                        const SizedBox(width: 4),
                                        Text('$streak',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800))
                                      ]),
                                      const SizedBox(height: 24),
                                      const Text('YOUR DAILY DOSE OF CURIOSITY',
                                          style: TextStyle(
                                              color: green,
                                              fontSize: 11,
                                              letterSpacing: .6,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 7),
                                      Text('Small steps.\nBrighter thinking.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge),
                                      const SizedBox(height: 20),
                                    ] else ...[
                                      Text(
                                          tab == 1
                                              ? '${activeLanguage == null ? 'Your' : languageName(activeLanguage!)} Learning Path'
                                              : tab == 2
                                                  ? 'Practice'
                                                  : 'Your Progress',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall),
                                      const SizedBox(height: 12),
                                    ],
                                    if (saveFailed)
                                      MaterialBanner(
                                          content: const Text(
                                              'Progress could not be saved.'),
                                          actions: [
                                            TextButton(
                                                onPressed: persist,
                                                child:
                                                    const Text('Retry saving'))
                                          ]),
                                    if (tab == 0) ...overview(),
                                    if (tab == 1) ...path(),
                                    if (tab == 2) ...practicePage(),
                                    if (tab == 3) ...progress(),
                                    const SizedBox(height: 20),
                                  ])))),
            ])),
            bottomNavigationBar: wide
                ? null
                : DecoratedBox(
                    decoration: const BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Color(0xFFF0F0F4)))),
                    child: NavigationBar(
                        height: 68,
                        backgroundColor: Colors.white,
                        indicatorColor: Colors.transparent,
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        selectedIndex: tab,
                        onDestinationSelected: (i) => setState(() => tab = i),
                        destinations: List.generate(
                            5,
                            (i) => NavigationDestination(
                                icon: Icon(navIcons[i], size: 24),
                                label: navLabels[i])))));
      });
  List<Widget> practicePage() => [
        const Text('Sharpen your skills with\nhands-on activities.',
            style: TextStyle(fontSize: 16, color: Color(0xFF62626B))),
        const SizedBox(height: 24),
        PracticeTile(
            title: 'Code Playground',
            subtitle: 'Write and run code — setup included',
            icon: Icons.play_circle_outline,
            color: questGreen,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CodeRunnerPage(prefs: widget.prefs)))),
        PracticeTile(
            title: 'Predict the Output',
            subtitle: 'What will this code print?',
            icon: Icons.code,
            color: const Color(0xFF9362E7),
            onTap: () => codingLab(QuestionKind.output)),
        PracticeTile(
            title: 'Fill in the Missing Code',
            subtitle: 'Complete the code snippets',
            icon: Icons.extension_rounded,
            color: const Color(0xFFFF9B00),
            onTap: () => codingLab(QuestionKind.blank)),
        PracticeTile(
            title: 'Arrange Code Lines',
            subtitle: 'Put the lines in the correct order',
            icon: Icons.sort_rounded,
            color: const Color(0xFF16ACE5),
            onTap: () => codingLab(QuestionKind.order)),
        PracticeTile(
            title: 'Find the Bugs',
            subtitle: 'Spot and understand the errors',
            icon: Icons.bug_report_rounded,
            color: const Color(0xFFFF4D87),
            onTap: () => codingLab(QuestionKind.bug)),
        const SizedBox(height: 12),
        mistakesCard(),
        PracticeTile(
            title: 'Daily challenge',
            subtitle: 'Five mixed questions · +30 XP',
            icon: Icons.bolt,
            color: const Color(0xFFFFB900),
            onTap: challenge),
      ];
  List<Widget> overview() {
    final next = lessons.indexWhere((l) => (scores[l.id] ?? 0) < 2);
    return [
      languageBar(),
      QuestEntrance(
          child: Row(children: [
        QuestBuddy(avatar: widget.prefs.getInt('avatar') ?? 2, size: 84),
        const SizedBox(width: 12),
        Expanded(
            child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF6F5FA),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    'Ready for today’s\nchallenge${(widget.prefs.getString('profileName') ?? '').isEmpty ? '' : ', ${widget.prefs.getString('profileName')}'}?',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15))))
      ])),
      const SizedBox(height: 24),
      QuestHero(
          title: next < 0
              ? 'Your next adventure\nis waiting.'
              : 'Your next big idea\nstarts here.',
          action:
              next < 0 ? 'Review a lesson' : 'Start: ${lessons[next].title}',
          onStart: () => openLesson(next < 0 ? 0 : next)),
      const SizedBox(height: 24),
      QuestStats(
          xp: xp, streak: streak, completed: completed, total: lessons.length),
      const SizedBox(height: 20),
      PracticeTile(
          title: 'Continue your learning path',
          subtitle: '${lessons.length} chapters. Three stages. Real progress.',
          icon: Icons.menu_book_rounded,
          color: green,
          onTap: () => setState(() => tab = 1)),
      PracticeTile(
          title: 'Learning toolkit · Goals, bookmarks & coding',
          subtitle: 'Your daily mission, pocket library and reminders',
          icon: Icons.auto_awesome_rounded,
          color: questBlue,
          onTap: toolkit),
      mistakesCard(),
    ];
  }

  Widget stat(String label, String value, IconData icon, Color color) =>
      Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(22)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 22, color: ink),
            const SizedBox(height: 14),
            Text(value,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(fontSize: 12))
          ]));
  List<Widget> path() => [
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['All lessons', 'Available', 'Completed']
                .map((f) => ChoiceChip(
                    label: Text(f),
                    selected: filter == f,
                    onSelected: (_) => setState(() => filter = f)))
                .toList()),
        const SizedBox(height: 18),
        QuestPath(
            scores: scores,
            onLesson: openLesson,
            unlocked: unlocked,
            filter: filter),
      ];
  Widget lessonCard(int i) {
    final l = lessons[i];
    final available = unlocked(i);
    final score = scores[l.id];
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: available ? () => openLesson(i) : null,
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color:
                                  available ? const Color(0xFFEAF1DF) : paper,
                              borderRadius: BorderRadius.circular(16)),
                          child: Icon(available ? l.icon : Icons.lock_outline,
                              color: available ? green : Colors.grey)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('CHAPTER ${i + 1}  ·  ${l.minutes} MIN',
                                style: const TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(l.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 17)),
                            Text(
                                !available
                                    ? 'Pass the previous chapter to unlock'
                                    : score == null
                                        ? 'A short lesson + 3 questions'
                                        : 'Best score: $score/3${score >= 2 ? ' · Passed' : ' · Try again'}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54))
                          ])),
                      const SizedBox(width: 8),
                      Icon(
                          (score ?? 0) >= 2
                              ? Icons.check_circle
                              : Icons.arrow_forward,
                          color: available ? green : Colors.grey,
                          size: 22)
                    ])))));
  }

  List<Widget> progress() => [
        Wrap(
            spacing: 6,
            runSpacing: 6,
            children: StudyLanguage.values
                .map((l) => ChoiceChip(
                    label: Text(languageName(l)),
                    selected: activeLanguage == l,
                    onSelected: (_) async {
                      if (await widget.prefs.setString('language', l.name) &&
                          mounted) {
                        setState(() => activeLanguage = l);
                      }
                    }))
                .toList()),
        ProgressSummary(
            passed: completed, total: lessons.length, xp: xp, streak: streak),
        const Divider(color: Color(0xFFECECF2)),
        const SizedBox(height: 18),
        const Text('Topic Mastery',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        ...lessons.map((l) {
          final data =
              Map<String, dynamic>.from(learning.mastery[l.title] ?? {});
          final attempts = (data['attempts'] as num?)?.toInt() ?? 0,
              correct = (data['correct'] as num?)?.toInt() ?? 0;
          final rate = attempts == 0 ? 0.0 : correct / attempts;
          return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(children: [
                Expanded(
                    flex: 4,
                    child: Text(l.title.split(' · ').last,
                        style: const TextStyle(fontSize: 13))),
                const SizedBox(width: 12),
                Expanded(
                    flex: 4,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: rate,
                            minHeight: 11,
                            backgroundColor: const Color(0xFFE8E8EE),
                            color: rate > .8
                                ? questLime
                                : const Color(0xFFB5E68D)))),
                const SizedBox(width: 10),
                SizedBox(
                    width: 38,
                    child: Text(
                        attempts == 0 ? '—' : '${(rate * 100).round()}%',
                        style: const TextStyle(fontSize: 12)))
              ]));
        }),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          badge('First steps', 'Pass one lesson', Icons.eco, completed >= 1),
          badge('Path finder', 'Pass every lesson', Icons.school,
              completed == lessons.length)
        ]),
        const SizedBox(height: 24),
        PracticeTile(
            title: 'Open learning toolkit',
            subtitle: 'Daily goals, saved lessons and reminders',
            icon: Icons.auto_awesome,
            color: questBlue,
            onTap: toolkit),
        OutlinedButton.icon(
            onPressed: reset,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset my progress')),
      ];
  Widget badge(String title, String subtitle, IconData icon, bool earned) =>
      Container(
          width: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: earned ? const Color(0xFFEAF8D8) : Colors.white,
              borderRadius: BorderRadius.circular(22)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 32, color: earned ? green : Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(earned ? 'UNLOCKED' : 'KEEP GOING',
                style: const TextStyle(
                    fontSize: 9, letterSpacing: 1.5, color: green))
          ]));
  Future<void> reset() async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Start a fresh chapter?'),
                content: const Text(
                    'This removes your scores, saved mistakes, streak and daily challenge history on this device.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Keep progress')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Reset'))
                ]));
    if (yes == true && mounted) {
      setState(() {
        scores.clear();
        days.clear();
        daily.clear();
        mistakes.clear();
        learning.reset();
      });
      await persist();
    }
  }
}

class LessonPage extends StatelessWidget {
  final Lesson lesson;
  final LearningData? learning;
  final ValueChanged<Map<Question, bool>>? onComplete;
  const LessonPage(
      {super.key, required this.lesson, this.learning, this.onComplete});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Learning room'),
          backgroundColor: paper,
          actions: [
            if (learning != null)
              AnimatedBuilder(
                  animation: learning!,
                  builder: (context, _) => IconButton(
                      tooltip: 'Bookmark lesson',
                      icon: Icon(learning!.bookmarks.contains(lesson.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border),
                      onPressed: () => learning!.toggle(lesson.id)))
          ]),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(padding: const EdgeInsets.all(24), children: [
                Text('${lesson.minutes} MIN READ  ·  PROGRAMMING FOUNDATIONS',
                    style: const TextStyle(
                        color: green,
                        fontSize: 11,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(lesson.title,
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                Text(lesson.subtitle,
                    style:
                        const TextStyle(fontSize: 17, color: Colors.black54)),
                const SizedBox(height: 28),
                ...lesson.sections.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 10),
                          Text(s.$2,
                              style: const TextStyle(fontSize: 17, height: 1.8))
                        ]))),
                CodePanel(code: lesson.code),
                const SizedBox(height: 24),
                const Text(
                    'Ready to put it into practice?\nAnswer 2 of 3 correctly to unlock the next chapter.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final mode = learning == null
                          ? const QuizPreferences(false, false)
                          : await chooseQuizPreferences(
                              context, learning!.prefs);
                      if (mode == null || !context.mounted) return;
                      final result = await nav.push<int>(MaterialPageRoute(
                          builder: (_) => QuizPage(
                              title: lesson.title,
                              onComplete: onComplete,
                              timed: mode.challenge,
                              autoAdvance: mode.autoAdvance,
                              avatar: learning?.prefs.getInt('avatar') ?? 2,
                              questions: mode.challenge &&
                                      lesson.challengeQuestions.isNotEmpty
                                  ? lesson.challengeQuestions
                                  : lesson.questions)));
                      if (result != null && context.mounted) nav.pop(result);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Take the quiz')),
                const SizedBox(height: 32)
              ]))));
}

class QuizPage extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final bool timed;
  final bool practiceMode;
  final bool labMode;
  final bool dailyChallenge;
  final bool autoAdvance;
  final int avatar;
  final ValueChanged<Map<Question, bool>>? onComplete;
  const QuizPage(
      {super.key,
      required this.title,
      required this.questions,
      this.timed = false,
      this.practiceMode = false,
      this.labMode = false,
      this.dailyChallenge = false,
      this.autoAdvance = false,
      this.avatar = 0,
      this.onComplete});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with WidgetsBindingObserver {
  Timer? advanceTimer;
  int advanceSeconds = 5;
  late bool autoNext;
  bool confirmingExit = false;
  int index = 0, score = 0, remaining = 30;
  int? selected;
  List<int> order = [];
  bool checked = false, finished = false, timedOut = false, leaving = false;
  final Map<Question, bool> answers = {};
  Timer? timer;
  @override
  void initState() {
    super.initState();
    autoNext = widget.autoAdvance;
    WidgetsBinding.instance.addObserver(this);
    setupQuestion();
    startTimer();
  }

  void setupQuestion() {
    order = List.generate(widget.questions[index].options.length, (i) => i);
    if (widget.questions[index].kind == QuestionKind.order) {
      selected = orderCorrect ? widget.questions[index].answer : -1;
    }
  }

  bool get orderCorrect {
    final expected = widget.questions[index].answerOrder;
    return order.length == expected.length &&
        List.generate(order.length, (i) => order[i] == expected[i])
            .every((v) => v);
  }

  void startAuto() {
    advanceTimer?.cancel();
    if (!autoNext || !checked || finished || leaving || confirmingExit) return;
    setState(() => advanceSeconds = 5);
    advanceTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (advanceSeconds <= 1) {
        t.cancel();
        next();
      } else {
        setState(() => advanceSeconds--);
      }
    });
  }

  void toggleAuto() {
    advanceTimer?.cancel();
    setState(() => autoNext = !autoNext);
    if (autoNext && checked) startAuto();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      advanceTimer?.cancel();
    } else if (checked) {
      startAuto();
    }
  }

  void startTimer() {
    if (!widget.timed) return;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        remaining--;
        if (remaining <= 0) {
          checked = true;
          timedOut = true;
          SoundEffects.instance.play(SoundCue.incorrect);
          answers[widget.questions[index]] = false;
          t.cancel();
        }
      });
      if (checked) startAuto();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    advanceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void check() {
    if (selected == null || checked) return;
    timer?.cancel();
    setState(() {
      checked = true;
      final correct = selected == widget.questions[index].answer;
      SoundEffects.instance
          .play(correct ? SoundCue.correct : SoundCue.incorrect);
      answers[widget.questions[index]] = correct;
      if (correct) score++;
    });
    startAuto();
  }

  void next() {
    if (!checked || finished) return;
    advanceTimer?.cancel();
    timer?.cancel();
    if (index == widget.questions.length - 1) {
      setState(() => finished = true);
      if (widget.dailyChallenge ||
          widget.labMode ||
          widget.practiceMode ||
          score >= 2) {
        SoundEffects.instance.play(SoundCue.complete);
      }
      return;
    }
    setState(() {
      index++;
      selected = null;
      checked = false;
      timedOut = false;
      remaining = 30;
    });
    setupQuestion();
    startTimer();
  }

  Future<void> exit() async {
    final nav = Navigator.of(context);
    if (finished) {
      if (leaving) return;
      widget.onComplete?.call(Map.unmodifiable(answers));
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) nav.pop(score);
      });
      return;
    }
    advanceTimer?.cancel();
    confirmingExit = true;
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Leave this quiz?'),
                content: const Text(
                    'Your answers in this attempt will not be saved. The challenge timer continues while this dialog is open.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Keep learning')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Leave quiz'))
                ]));
    confirmingExit = false;
    if (yes != true && mounted && checked) startAuto();
    if (yes == true && mounted) {
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) nav.pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) exit();
      },
      child: Scaffold(
          appBar: AppBar(
              title: Text(widget.title),
              actions: [
                if (!finished)
                  IconButton(
                      tooltip:
                          autoNext ? 'Pause auto-next' : 'Enable auto-next',
                      icon: Icon(autoNext
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline),
                      onPressed: toggleAuto)
              ],
              backgroundColor: paper,
              leading: IconButton(
                  tooltip: 'Leave quiz',
                  icon: const Icon(Icons.close),
                  onPressed: exit)),
          body: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: finished ? result() : question()))));
  void moveLine(int position, int delta) => setState(() {
        final item = order.removeAt(position);
        order.insert(position + delta, item);
        selected = orderCorrect ? widget.questions[index].answer : -1;
      });
  Widget question() {
    final q = widget.questions[index];
    return ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [
        Text('QUESTION ${index + 1} OF ${widget.questions.length}',
            style: const TextStyle(
                color: green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3)),
        const Spacer(),
        if (widget.timed)
          Text('${remaining}s',
              style: TextStyle(
                  color: remaining < 10 ? Colors.red : green,
                  fontWeight: FontWeight.bold))
      ]),
      const SizedBox(height: 14),
      ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: QuestProgress(value: (index + 1) / widget.questions.length)),
      const SizedBox(height: 32),
      if (q.kind != QuestionKind.choice)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Icon(
                  q.kind == QuestionKind.bug
                      ? Icons.bug_report_rounded
                      : q.kind == QuestionKind.order
                          ? Icons.swap_vert_rounded
                          : q.kind == QuestionKind.output
                              ? Icons.terminal_rounded
                              : Icons.extension_rounded,
                  color: questBlue),
              const SizedBox(width: 8),
              Text(
                  {
                    QuestionKind.output: 'OUTPUT DETECTIVE',
                    QuestionKind.blank: 'FILL THE GAP',
                    QuestionKind.order: 'CODE SHUFFLE',
                    QuestionKind.bug: 'BUG HUNT'
                  }[q.kind]!,
                  style: const TextStyle(
                      color: questBlue,
                      letterSpacing: 1,
                      fontSize: 12,
                      fontWeight: FontWeight.w900))
            ])),
      QuestEntrance(
          key: ValueKey('question-$index'),
          child:
              Text(q.prompt, style: Theme.of(context).textTheme.headlineSmall)),
      const SizedBox(height: 12),
      if (q.kind == QuestionKind.order)
        const Text('Put the lines in the right order. No rush.'),
      const SizedBox(height: 16),
      if (q.code != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: CodePanel(code: q.code!)),
      if (q.kind == QuestionKind.order) ...[
        const Text('Drag the handle or use arrows to reorder the lines.'),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            if (checked) return;
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = order.removeAt(oldIndex);
              order.insert(newIndex, item);
              selected = orderCorrect ? q.answer : -1;
            });
          },
          children: List.generate(
              order.length,
              (position) => Card(
                  key: ValueKey('line-${order[position]}'),
                  child: ListTile(
                      leading: checked
                          ? const Icon(Icons.code)
                          : ReorderableDragStartListener(
                              index: position,
                              child: const Icon(Icons.drag_handle)),
                      title: Text(q.options[order[position]],
                          style: const TextStyle(fontFamily: 'monospace')),
                      trailing: SizedBox(
                          width: 96,
                          child: Row(children: [
                            IconButton(
                                tooltip: 'Move line up',
                                onPressed: checked || position == 0
                                    ? null
                                    : () => moveLine(position, -1),
                                icon: const Icon(Icons.arrow_upward, size: 18)),
                            IconButton(
                                tooltip: 'Move line down',
                                onPressed:
                                    checked || position == order.length - 1
                                        ? null
                                        : () => moveLine(position, 1),
                                icon:
                                    const Icon(Icons.arrow_downward, size: 18))
                          ]))))),
        ),
      ],
      if (q.kind != QuestionKind.order)
        ...List.generate(q.options.length, (i) {
          final correct = checked && i == q.answer;
          final wrong = checked && i == selected && !correct;
          final active = selected == i;
          return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(
                  selected: active,
                  button: true,
                  child: Material(
                      color: correct
                          ? const Color(0xFFEAF8D8)
                          : wrong
                              ? const Color(0xFFFFE1DB)
                              : active
                                  ? const Color(0xFFEAF8D8)
                                  : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                              color: active || correct
                                  ? green
                                  : const Color(0xFFE3E7DE),
                              width: active ? 2 : 1)),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: checked
                              ? null
                              : () {
                                  SoundEffects.instance.play(SoundCue.tap);
                                  setState(() => selected = i);
                                },
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                Text('',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: green)),
                                const SizedBox(width: 16),
                                Expanded(child: Text(q.options[i])),
                                if (correct)
                                  const Icon(Icons.check_circle, color: green),
                                if (wrong)
                                  const Icon(Icons.cancel_outlined,
                                      color: Colors.red)
                              ]))))));
        }),
      if (checked)
        QuestEntrance(
            key: ValueKey(index),
            shake: !timedOut && selected != q.answer,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF0E1),
                    borderRadius: BorderRadius.circular(18)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          timedOut
                              ? 'Time is up. Here is the idea.'
                              : selected == q.answer
                                  ? 'You got it!'
                                  : 'A good moment to learn.',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: green)),
                      const SizedBox(height: 8),
                      Text(q.explanation)
                    ]))),
      if (checked)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Expanded(
                  child: Text(autoNext
                      ? 'Next ${index == widget.questions.length - 1 ? "results" : "question"} in $advanceSeconds seconds'
                      : 'Auto-next paused. Continue when you are ready.')),
              TextButton(
                  onPressed: toggleAuto,
                  child: Text(autoNext ? 'Pause' : 'Auto-next'))
            ])),
      const SizedBox(height: 16),
      QuestButton(
        onPressed: checked
            ? next
            : selected == null
                ? null
                : check,
        label: checked
            ? index == widget.questions.length - 1
                ? 'See my results'
                : 'Next question'
            : 'Check answer',
      )
    ]);
  }

  Widget result() => QuestCelebration(
      celebrate: widget.dailyChallenge ||
          (widget.practiceMode ? score > 0 : score >= 2),
      child: ListView(padding: const EdgeInsets.all(32), children: [
        const SizedBox(height: 28),
        Center(
            child: QuestEntrance(
                child: QuestBuddy(
                    avatar: widget.avatar, celebrate: true, size: 130))),
        const SizedBox(height: 28),
        Text(
            score >= (widget.dailyChallenge ? 3 : 2)
                ? 'Look at you grow.'
                : 'Every try is progress.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        Text('$score / ${widget.questions.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 52, fontWeight: FontWeight.w900, color: green)),
        const SizedBox(height: 8),
        Text(
            widget.labMode
                ? 'Coding lab complete. Your topic mastery and mistakes are updated when you save. Chapter scores and XP stay unchanged.'
                : widget.practiceMode
                    ? '$score ${score == 1 ? 'mistake' : 'mistakes'} cleared. ${widget.questions.length - score} still to practice. No chapter scores or XP changed.'
                    : widget.dailyChallenge
                        ? 'Daily challenge complete. +30 bonus XP!'
                        : score >= 2
                            ? 'Chapter passed! Continue your learning path.'
                            : 'Review the lesson and try again. You need 2 correct answers to pass.',
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        FilledButton(onPressed: exit, child: const Text('Save & continue')),
        const SizedBox(height: 16),
        const Text('Progress is saved when you continue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54))
      ]));
}
