import 'package:flutter/material.dart';
import 'polished_panels.dart';
import 'reference_design.dart';
import 'quest_motion.dart';

class LearningDemo extends StatefulWidget {
  const LearningDemo({super.key});

  @override
  State<LearningDemo> createState() => _LearningDemoState();
}

class _LearningDemoState extends State<LearningDemo> {
  int step = 0;
  int? answer;
  bool checked = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('LearnCodz Demo')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              key: ValueKey(step),
              padding: const EdgeInsets.all(24),
              children: [
                LinearProgressIndicator(
                    value: (step + 1) / 3,
                    borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 20),
                QuestEntrance(
                    child: FeatureBanner(
                  eyebrow: 'QUICK DEMO · ${step + 1} OF 3',
                  title: [
                    'See how learning works',
                    'Predict the output',
                    'You’re ready to learn'
                  ][step],
                  subtitle: [
                    'Read a short lesson, try a question, then use the feedback to improve.',
                    'A program can store a number, change it, and show the result.',
                    'Follow your learning path or explore a hands-on mission in Practice.'
                  ][step],
                  icon: [
                    Icons.route_rounded,
                    Icons.terminal_rounded,
                    Icons.verified_rounded
                  ][step],
                )),
                if (step == 1) ...[
                  const CodePanel(
                      code: 'points = 3\npoints = points + 2\nprint(points)'),
                  const SizedBox(height: 16),
                  const Text('What does this Python example print?',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 8, children: [
                    for (final option in [2, 3, 5])
                      ChoiceChip(
                          label: Text('$option'),
                          selected: answer == option,
                          onSelected: checked
                              ? null
                              : (_) => setState(() => answer = option)),
                  ]),
                  if (checked) ...[
                    const SizedBox(height: 16),
                    ToolkitPanel(
                        title: answer == 5 ? 'You got it!' : 'The answer is 5',
                        children: const [
                          Text(
                              'The variable starts at 3. Adding 2 updates it to 5, and print shows that updated value.'),
                        ]),
                  ],
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: step == 1 && answer == null
                      ? null
                      : () {
                          if (step == 2) {
                            Navigator.pop(context);
                            return;
                          }
                          setState(() {
                            if (step == 1 && !checked) {
                              checked = true;
                            } else {
                              step++;
                            }
                          });
                        },
                  child: Text(step == 0
                      ? 'Try a question'
                      : step == 2
                          ? 'Back to LearnCodz'
                          : checked
                              ? 'Continue'
                              : 'Check answer'),
                ),
                const SizedBox(height: 12),
                const Text(
                    'Demo answers don’t affect your XP, streak or progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}
