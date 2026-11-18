import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

enum QuestAnimation { flame, grow, celebrate }

void registerAnimationLicenses() {
  LicenseRegistry.addLicense(() async* {
    final notice = await rootBundle.loadString('assets/animations/NOTICE.txt');
    final license =
        await rootBundle.loadString('assets/animations/CC-BY-4.0.txt');
    yield LicenseEntryWithLineBreaks(
        ['Animated Noto Emoji'], '$notice\n\n$license');
  });
}

/// All artwork is bundled. No network requests are needed during playback.
class QuestLottie extends StatefulWidget {
  final QuestAnimation animation;
  final double size;
  final bool repeat;
  const QuestLottie(
      {super.key,
      required this.animation,
      this.size = 96,
      this.repeat = false});

  Widget get still => Icon(
        switch (animation) {
          QuestAnimation.flame => Icons.local_fire_department_rounded,
          QuestAnimation.grow => Icons.eco_rounded,
          QuestAnimation.celebrate => Icons.celebration_rounded,
        },
        size: size * .7,
        color: switch (animation) {
          QuestAnimation.flame => const Color(0xFFFF8A24),
          QuestAnimation.grow => const Color(0xFF52962C),
          QuestAnimation.celebrate => const Color(0xFFFFC94F),
        },
      );

  @override
  State<QuestLottie> createState() => _QuestLottieState();
}

class _QuestLottieState extends State<QuestLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion;
  @override
  void initState() {
    super.initState();
    motion = AnimationController(vsync: this);
  }

  bool loaded = false;
  bool reduced = false;

  void play() {
    if (!loaded) {
      return;
    }
    motion.stop();
    if (reduced) {
      return;
    }
    motion.reset();
    if (widget.repeat) {
      motion.repeat();
    } else {
      motion.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = MediaQuery.disableAnimationsOf(context);
    if (next != reduced) {
      reduced = next;
      play();
    }
  }

  @override
  void didUpdateWidget(QuestLottie old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      loaded = false;
      motion.stop();
    } else if (old.repeat != widget.repeat) {
      play();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      image: true,
      label: switch (widget.animation) {
        QuestAnimation.flame => 'Streak flame',
        QuestAnimation.grow => 'Learning progress refreshing',
        QuestAnimation.celebrate => 'Celebration'
      },
      child: ExcludeSemantics(
          child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: reduced
                  ? widget.still
                  : Lottie.asset(
                      'assets/animations/${widget.animation.name}.json',
                      key: ValueKey(widget.animation),
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.contain,
                      controller: motion,
                      animate: false,
                      repeat: false,
                      onLoaded: (composition) {
                        if (!mounted) {
                          return;
                        }
                        motion.duration =
                            widget.animation == QuestAnimation.grow
                                ? const Duration(milliseconds: 1200)
                                : composition.duration;
                        loaded = true;
                        play();
                      },
                      frameRate: const FrameRate(30),
                      backgroundLoading: false,
                      frameBuilder: (context, child, composition) =>
                          composition == null ? widget.still : child,
                      errorBuilder: (_, __, ___) => widget.still,
                    ))));
}

class AnimationPreviewPage extends StatefulWidget {
  const AnimationPreviewPage({super.key});
  @override
  State<AnimationPreviewPage> createState() => _AnimationPreviewPageState();
}

class _AnimationPreviewPageState extends State<AnimationPreviewPage> {
  final plays = <QuestAnimation, int>{};
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Animation preview')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  const Text('A little life in every win.',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                      'Bundled animations play offline. Tap replay to see one again.',
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
                  for (final animation in QuestAnimation.values)
                    Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            color: animation == QuestAnimation.flame
                                ? const Color(0xFFFFF5E8)
                                : animation == QuestAnimation.grow
                                    ? const Color(0xFFEFF8E6)
                                    : const Color(0xFFF4EFFE),
                            borderRadius: BorderRadius.circular(24)),
                        child: Row(children: [
                          QuestLottie(
                              key: ValueKey(
                                  '${animation.name}-${plays[animation] ?? 0}'),
                              animation: animation,
                              size: 88),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Text(
                                  switch (animation) {
                                    QuestAnimation.flame => 'Streak flame',
                                    QuestAnimation.grow => 'Refresh & grow',
                                    QuestAnimation.celebrate =>
                                      'Celebrate a win'
                                  },
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800))),
                          IconButton(
                              tooltip: 'Replay ${animation.name}',
                              onPressed: () => setState(() => plays[animation] =
                                  (plays[animation] ?? 0) + 1),
                              icon: const Icon(Icons.replay_rounded,
                                  color: Color(0xFF419500)))
                        ])),
                  const Text(
                      'Animated Noto Emoji by Google · CC BY 4.0. Playback respects reduced-motion settings.',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ]))),
      );
}
