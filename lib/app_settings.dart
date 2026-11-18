import 'lottie_effects.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_progress.dart';
import 'sound_effects.dart';
import 'polished_panels.dart';

class AppSettingsPage extends StatelessWidget {
  final SharedPreferences prefs;
  final VoidCallback onReminders;
  final Future<void> Function() onReset;
  const AppSettingsPage(
      {super.key,
      required this.prefs,
      required this.onReminders,
      required this.onReset});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(padding: const EdgeInsets.all(24), children: [
                const FeatureBanner(
                    eyebrow: 'YOUR APP, YOUR WAY',
                    title: 'Find your rhythm.',
                    subtitle:
                        'Manage your account, learning sounds and reminders in one place.',
                    icon: Icons.tune_rounded,
                    color: Color(0xFF8870CD)),
                const CloudAccountCard(),
                SoundSettings(prefs: prefs),
                const SizedBox(height: 20),
                Material(
                    color: const Color(0xFFF6F8F2),
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        leading: const Icon(Icons.notifications_active_outlined,
                            color: Color(0xFF608B3B)),
                        title: const Text('Learning reminders',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text('Choose your daily nudge'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: onReminders)),
                const SizedBox(height: 30),
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F5),
                        border: Border.all(color: const Color(0xFFF3DDD7)),
                        borderRadius: BorderRadius.circular(22)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start over',
                              style: TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text(
                              'Clear your learning progress and begin again. You will be asked to confirm before anything is reset.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                              onPressed: onReset,
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFB54C3B)),
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Reset my progress'))
                        ])),
                const SizedBox(height: 24),
                ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.groups_outlined,
                        color: Color(0xFF8870CD)),
                    title: const Text('About developers',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    children: const [
                      ListTile(
                          title: Text('Zulkifal Khan'),
                          subtitle: Text('2430-0071')),
                      ListTile(
                          title: Text('Jamal Akbar Khan'),
                          subtitle: Text('2430-0205')),
                      Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              'LearnCodz · Learn programming, one small win at a time.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)))
                    ]),
                const SizedBox(height: 12),
                ExpansionTile(
                    leading: const Icon(Icons.animation_rounded,
                        color: Color(0xFF608B3B)),
                    title: const Text('Animation credits'),
                    children: [
                      TextButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AnimationPreviewPage())),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Preview animations')),
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              'Animated Noto Emoji by Google. Licensed under CC BY 4.0. Artwork is bundled unmodified and plays offline.',
                              style: TextStyle(fontSize: 13, height: 1.5))),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SelectableText(
                              'https://googlefonts.github.io/noto-emoji-files/\nhttps://creativecommons.org/licenses/by/4.0/',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54))),
                      TextButton(
                          onPressed: () => showLicensePage(
                              context: context, applicationName: 'LearnCodz'),
                          child: const Text('View open-source licenses'))
                    ])
              ]))));
}
