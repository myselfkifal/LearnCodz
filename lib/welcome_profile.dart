import 'polished_panels.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_courses.dart';
import 'quest_motion.dart';
import 'quest_widgets.dart';
import 'reference_design.dart';

const avatarColors = [
  Color(0xFF58CC02),
  Color(0xFF1CB0F6),
  Color(0xFFAA70E8),
  Color(0xFFFFA326)
];

class QuestBuddy extends StatelessWidget {
  final int avatar;
  final bool celebrate;
  final double size;
  const QuestBuddy(
      {super.key, this.avatar = 0, this.celebrate = false, this.size = 120});
  @override
  Widget build(BuildContext context) => Semantics(
      label: celebrate
          ? 'Happy LearnCodz learning buddy'
          : 'LearnCodz learning buddy',
      image: true,
      child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
              painter: _BuddyPainter(
                  avatarColors[avatar % avatarColors.length], celebrate))));
}

class _BuddyPainter extends CustomPainter {
  final Color color;
  final bool happy;
  _BuddyPainter(this.color, this.happy);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 120);
    final fill = Paint()..color = color;
    canvas.drawOval(const Rect.fromLTWH(22, 103, 76, 10),
        Paint()..color = color.withValues(alpha: .16));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 22, 84, 78), const Radius.circular(30)),
        fill);
    canvas.drawCircle(const Offset(18, 63), 10, fill);
    canvas.drawCircle(const Offset(102, 63), 10, fill);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(31, 42, 58, 35), const Radius.circular(15)),
        Paint()..color = Colors.white);
    final ink = Paint()
      ..color = const Color(0xFF17352A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final x in [46.0, 74.0]) {
      if (happy) {
        canvas.drawArc(Rect.fromCircle(center: Offset(x, 59), radius: 5), 3.3,
            2.8, false, ink);
      } else {
        canvas.drawCircle(
            Offset(x, 58), 3, Paint()..color = const Color(0xFF17352A));
      }
    }
    canvas.drawArc(const Rect.fromLTWH(48, 72, 24, 16), .15, 2.8, false, ink);
    canvas.drawLine(const Offset(60, 22), const Offset(60, 12), ink);
    canvas.drawCircle(const Offset(60, 10), 6, fill);
    if (happy) {
      for (final x in [9.0, 110.0]) {
        canvas.drawLine(Offset(x - 4, 21), Offset(x + 4, 21),
            ink..color = const Color(0xFFFFC800));
        canvas.drawLine(Offset(x, 17), Offset(x, 25), ink);
      }
    }
  }

  @override
  bool shouldRepaint(_BuddyPainter old) =>
      old.color != color || old.happy != happy;
}

class LaunchScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final Widget Function() dashboard;
  final bool showSplash;
  const LaunchScreen(
      {super.key,
      required this.prefs,
      required this.dashboard,
      this.showSplash = true});
  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  bool splash = true;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    splash = widget.showSplash;
    activeLanguage = parseLanguage(widget.prefs.getString('language'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.showSplash) return;
    timer ??= Timer(
        Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 100 : 1400),
        () {
      if (mounted) setState(() => splash = false);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (splash) {
      return Scaffold(
          body: Center(
              child: QuestEntrance(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
        QuestBuddy(avatar: widget.prefs.getInt('avatar') ?? 2, size: 150),
        const SizedBox(height: 22),
        const Text('LearnCodz',
            style: TextStyle(
                fontSize: 40, fontWeight: FontWeight.w900, color: questGreen)),
        const Text('Small steps. Big possibilities.'),
        const SizedBox(height: 28),
      ]))));
    }
    if (activeLanguage == null) {
      return LanguagePicker(
          prefs: widget.prefs,
          onSelected: (l) => setState(() => activeLanguage = l));
    }
    return widget.dashboard();
  }
}

class LanguagePicker extends StatefulWidget {
  final SharedPreferences prefs;
  final ValueChanged<StudyLanguage> onSelected;
  final bool switching;
  const LanguagePicker(
      {super.key,
      required this.prefs,
      required this.onSelected,
      this.switching = false});
  @override
  State<LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  StudyLanguage? selected;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    selected = parseLanguage(widget.prefs.getString('language'));
  }

  Future<void> choose() async {
    if (selected == null || saving) return;
    setState(() => saving = true);
    try {
      if (!await widget.prefs.setString('language', selected!.name)) {
        throw StateError('Could not save');
      }
      if (mounted) widget.onSelected(selected!);
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Could not save your language. Please retry.';
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: widget.switching
          ? AppBar(title: const Text('Choose a Language'))
          : null,
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    if (!widget.switching) ...[
                      Center(
                          child: QuestEntrance(
                              child: QuestBuddy(
                                  avatar: widget.prefs.getInt('avatar') ?? 2,
                                  size: 80))),
                      const SizedBox(height: 12),
                      const Text('Welcome, future coder!',
                          style: TextStyle(
                              fontSize: 13,
                              color: questGreen,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8)
                    ],
                    if (!widget.switching)
                      const Text('Choose a Language',
                          style: TextStyle(
                              fontSize: 27, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    const Text(
                        'Which programming language\ndo you want to learn?',
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFF5D5D65))),
                    const SizedBox(height: 28),
                    GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.02,
                        children: StudyLanguage.values
                            .map((l) => Semantics(
                                selected: selected == l,
                                button: true,
                                child: Material(
                                    color: selected == l
                                        ? const Color(0xFFF0FAE5)
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        side: BorderSide(
                                            color: selected == l
                                                ? questGreen
                                                : const Color(0xFFE4E4EC),
                                            width: selected == l ? 1.7 : 1.2)),
                                    child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: saving
                                            ? null
                                            : () =>
                                                setState(() => selected = l),
                                        child: Stack(children: [
                                          Center(
                                              child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                LanguageMark(language: l),
                                                const SizedBox(height: 14),
                                                Text(languageName(l),
                                                    style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w800))
                                              ])),
                                          if (selected == l)
                                            const Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Icon(Icons.check_circle,
                                                    color: questGreen,
                                                    size: 24))
                                        ])))))
                            .toList()),
                    const SizedBox(height: 32),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    QuestButton(
                        label: saving
                            ? 'Saving...'
                            : selected == null
                                ? 'Choose your language'
                                : "Let's learn ${languageName(selected!)}",
                        onPressed: selected == null || saving ? null : choose),
                    const SizedBox(height: 14),
                    const Text(
                        'You can switch later. Each language keeps its own lesson progress.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ])))));
}

class ProfilePage extends StatefulWidget {
  final SharedPreferences prefs;
  const ProfilePage({super.key, required this.prefs});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  late TextEditingController name, email;
  late int avatar;
  bool busy = false;
  String? message;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(
        text: widget.prefs.getString('profileName') ?? '');
    email = TextEditingController(
        text: widget.prefs.getString('profileEmail') ?? '');
    avatar = widget.prefs.getInt('avatar') ?? 2;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() => busy = true);
    try {
      final results = await Future.wait([
        widget.prefs.setString('profileName', name.text.trim()),
        widget.prefs.setString('profileEmail', email.text.trim().toLowerCase()),
        widget.prefs.setInt('avatar', avatar)
      ]);
      if (results.any((v) => !v)) throw StateError('Save failed');
      if (mounted) {
        setState(() => message = 'Profile saved. Your buddy is ready!');
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Could not save your profile. Please retry.');
      }
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: QuestEntrance(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Form(
                      key: form,
                      child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const FeatureBanner(
                                eyebrow: 'MAKE IT YOURS',
                                title: 'Your coder identity.',
                                subtitle:
                                    'A name, a buddy and a little personality. Ready for your next adventure.',
                                icon: Icons.face_rounded,
                                color: Color(0xFF9470D7)),
                            Center(
                                child: QuestEntrance(
                                    key: ValueKey(avatar),
                                    child: QuestBuddy(
                                        avatar: avatar, celebrate: true))),
                            const SizedBox(height: 12),
                            const Text('Pick your learning buddy',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                children: List.generate(
                                    4,
                                    (i) => IconButton(
                                        tooltip: 'Choose buddy ${i + 1}',
                                        onPressed: () =>
                                            setState(() => avatar = i),
                                        icon: CircleAvatar(
                                            backgroundColor: avatarColors[i],
                                            child: Icon(
                                                avatar == i
                                                    ? Icons.check
                                                    : Icons.face,
                                                color: Colors.white))))),
                            const SizedBox(height: 24),
                            TextFormField(
                                controller: name,
                                maxLength: 50,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                    labelText: 'Name',
                                    prefixIcon: Icon(Icons.person_outline),
                                    filled: true,
                                    fillColor: Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(16)),
                                        borderSide: BorderSide.none)),
                                validator: (v) => (v ?? '').trim().isEmpty
                                    ? 'Enter your name.'
                                    : null),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: email,
                                keyboardType: TextInputType.emailAddress,
                                maxLength: 100,
                                decoration: const InputDecoration(
                                    labelText: 'Gmail',
                                    prefixIcon: Icon(Icons.mail_outline),
                                    hintText: 'yourname@gmail.com',
                                    filled: true,
                                    fillColor: Color(0xFFF5F7FA),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(16)),
                                        borderSide: BorderSide.none)),
                                validator: (v) =>
                                    RegExp(r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@gmail\.com$')
                                            .hasMatch(
                                                (v ?? '').trim().toLowerCase())
                                        ? null
                                        : 'Enter a valid @gmail.com address.'),
                            const SizedBox(height: 12),
                            const Text(
                                'Profile edits save on this device and sync when signed in. This form does not change your login email.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 20),
                            QuestButton(
                                label: busy ? 'Saving...' : 'Save my profile',
                                onPressed: busy ? null : save),
                            if (message != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: QuestEntrance(
                                      key: ValueKey(message),
                                      child: Text(message!))),
                            const SizedBox(height: 30),
                            const SizedBox(height: 24),
                          ]))))));
}

class QuizPreferences {
  final bool challenge, autoAdvance;
  const QuizPreferences(this.challenge, this.autoAdvance);
}

Future<QuizPreferences?> chooseQuizPreferences(
    BuildContext context, SharedPreferences prefs) async {
  var challenge = prefs.getBool('challengeMode') ?? false;
  var auto = prefs.getBool('autoAdvance') ?? true;
  return showModalBottomSheet<QuizPreferences>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 540),
      builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialog) => SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        const Text('Choose your quest mode',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Pick the difficulty that fits your goal.',
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 24),
                        Container(
                            decoration: BoxDecoration(
                                color: !challenge
                                    ? const Color(0xFFF2FAE9)
                                    : Colors.white,
                                border: Border.all(
                                    color: !challenge
                                        ? questGreen
                                        : const Color(0xFFE2E2E8)),
                                borderRadius: BorderRadius.circular(18)),
                            child: RadioListTile<bool>(
                                value: false,
                                groupValue: challenge,
                                onChanged: (v) =>
                                    setDialog(() => challenge = v!),
                                title: const Text('Easy'),
                                subtitle: const Text(
                                    'Core basics. No question timer.'))),
                        const SizedBox(height: 12),
                        Container(
                            decoration: BoxDecoration(
                                color: challenge
                                    ? const Color(0xFFF2FAE9)
                                    : Colors.white,
                                border: Border.all(
                                    color: challenge
                                        ? questGreen
                                        : const Color(0xFFE2E2E8)),
                                borderRadius: BorderRadius.circular(18)),
                            child: RadioListTile<bool>(
                                value: true,
                                groupValue: challenge,
                                onChanged: (v) =>
                                    setDialog(() => challenge = v!),
                                title: const Text('Difficult'),
                                subtitle: const Text(
                                    'Code reasoning. 30 seconds per question.'))),
                        const SizedBox(height: 20),
                        const Divider(),
                        SwitchListTile(
                            value: auto,
                            onChanged: (v) => setDialog(() => auto = v),
                            title: const Text('Auto-next after 5 seconds'),
                            subtitle: const Text(
                                'You can pause the countdown to read feedback.')),
                        const SizedBox(height: 24),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Not now')),
                              FilledButton(
                                  onPressed: () async {
                                    try {
                                      final ok = await Future.wait([
                                        prefs.setBool(
                                            'challengeMode', challenge),
                                        prefs.setBool('autoAdvance', auto)
                                      ]);
                                      if (!ok.every((v) => v)) {
                                        throw StateError('Save failed');
                                      }
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext,
                                            QuizPreferences(challenge, auto));
                                      }
                                    } catch (_) {
                                      if (dialogContext.mounted) {
                                        ScaffoldMessenger.of(dialogContext)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Could not save quiz settings. Please retry.')));
                                      }
                                    }
                                  },
                                  child: const Text('Start quest'))
                            ]),
                      ]))))));
}
