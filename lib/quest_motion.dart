import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Finite animations respect the device's reduced-motion preference.
class QuestEntrance extends StatelessWidget {
  final Widget child;
  final bool shake;
  const QuestEntrance({super.key, required this.child, this.shake = false});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: shake ? 440 : 650),
      curve: Curves.linear,
      child: child,
      builder: (context, value, child) {
        if (shake) {
          return Transform.translate(
              offset:
                  Offset(math.sin(value * math.pi * 8) * 9 * (1 - value), 0),
              child: child);
        }
        final eased = Curves.easeOutBack.transform(value);
        return Opacity(
            opacity: (value * 3).clamp(0, 1),
            child: Transform.translate(
                offset: Offset(0, 20 * (1 - eased)),
                child:
                    Transform.scale(scale: .94 + .06 * eased, child: child)));
      },
    );
  }
}

class QuestPress extends StatefulWidget {
  final Widget child;
  const QuestPress({super.key, required this.child});
  @override
  State<QuestPress> createState() => _QuestPressState();
}

class _QuestPressState extends State<QuestPress> {
  bool down = false;
  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => setState(() => down = true),
        onPointerUp: (_) => setState(() => down = false),
        onPointerCancel: (_) => setState(() => down = false),
        child: AnimatedScale(
            scale: down ? .97 : 1,
            duration: Duration(
                milliseconds:
                    MediaQuery.disableAnimationsOf(context) ? 0 : 120),
            curve: Curves.easeOut,
            child: widget.child),
      );
}

class QuestProgress extends StatelessWidget {
  final double value;
  const QuestProgress({super.key, required this.value});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 12,
            backgroundColor: const Color(0xFFE5E9DF)),
      );
}

class QuestCelebration extends StatelessWidget {
  final Widget child;
  final bool celebrate;
  const QuestCelebration(
      {super.key, required this.child, required this.celebrate});
  @override
  Widget build(BuildContext context) {
    if (!celebrate || MediaQuery.disableAnimationsOf(context)) {
      return QuestEntrance(child: child);
    }
    return Stack(children: [
      QuestEntrance(child: child),
      Positioned.fill(
          child: IgnorePointer(
              child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1600),
        builder: (context, progress, _) =>
            CustomPaint(painter: _ConfettiPainter(progress)),
      )))),
    ]);
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1) return;
    const colors = [
      Color(0xFF58CC02),
      Color(0xFF1CB0F6),
      Color(0xFFFFC800),
      Color(0xFFFF78B7)
    ];
    for (var i = 0; i < 36; i++) {
      final x =
          size.width / 2 + math.sin(i * 2.4) * size.width * .55 * progress;
      final y = 65 +
          (i % 7) * 8 -
          math.sin(progress * math.pi) * 80 +
          progress * progress * 360;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 10 + i.toDouble());
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-3, -5, 6, 10), const Radius.circular(2)),
          Paint()
            ..color =
                colors[i % colors.length].withValues(alpha: 1 - progress));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
