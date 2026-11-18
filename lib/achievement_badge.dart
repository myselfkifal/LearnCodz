import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Original vector artwork: crisp at phone and desktop sizes, with no downloads.
class AchievementBadge extends StatelessWidget {
  final String title;
  final Color color;
  final bool unlocked;
  const AchievementBadge(
      {super.key,
      required this.title,
      required this.color,
      required this.unlocked});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 72,
      height: 78,
      child: CustomPaint(painter: _BadgePainter(title, color, unlocked)));
}

class _BadgePainter extends CustomPainter {
  final String title;
  final Color color;
  final bool unlocked;
  _BadgePainter(this.title, this.color, this.unlocked);
  Path polygon(List<Offset> points) => Path()..addPolygon(points, true);
  Path star(Offset center, double outer, double inner, int count) {
    return polygon(List.generate(count * 2, (i) {
      final angle = i * math.pi / count - math.pi / 2;
      final r = i.isEven ? outer : inner;
      return center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    }));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80, size.height / 86);
    final base = unlocked ? color : const Color(0xFFB2BAC7);
    final dark = Color.lerp(base, const Color(0xFF182740), .38)!;
    final light = Color.lerp(base, Colors.white, .48)!;
    final paint = Paint()..isAntiAlias = true;
    final ribbonLeft = polygon(const [
      Offset(20, 52),
      Offset(38, 58),
      Offset(28, 83),
      Offset(22, 75),
      Offset(11, 77)
    ]);
    final ribbonRight = polygon(const [
      Offset(42, 58),
      Offset(60, 52),
      Offset(69, 77),
      Offset(58, 75),
      Offset(52, 83)
    ]);
    canvas.drawPath(ribbonLeft, paint..color = dark);
    canvas.drawPath(ribbonRight, paint..color = base);
    final rim = star(const Offset(40, 35), 33, 29, 12);
    canvas.drawShadow(rim, const Color(0x60334150), 3, false);
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(rim, paint..color = dark);
    canvas.restore();
    canvas.drawPath(
        rim,
        paint
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [light, base])
              .createShader(const Rect.fromLTWH(7, 2, 66, 66)));
    paint.shader = null;
    canvas.drawCircle(
        const Offset(40, 35), 25, paint..color = dark.withValues(alpha: .28));
    canvas.drawCircle(
        const Offset(40, 33),
        23,
        paint
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(base, Colors.white, .75)!, light])
              .createShader(const Rect.fromLTWH(17, 10, 46, 46)));
    paint.shader = null;
    canvas.drawArc(
        const Rect.fromLTWH(17, 10, 46, 46),
        math.pi * 1.04,
        math.pi * .65,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
    // The offset silhouette gives each illustrated emblem a raised enamel edge.
    canvas.save();
    canvas.translate(0, 2);
    emblem(canvas, dark.withValues(alpha: .55));
    canvas.restore();
    emblem(canvas, unlocked ? dark : const Color(0xFF7E8B9D));
    if (unlocked) {
      canvas.drawPath(star(const Offset(65, 13), 5, 1.5, 4),
          paint..color = const Color(0xFFFFDB66));
      canvas.drawCircle(const Offset(11, 19), 2, paint..color = Colors.white);
    } else {
      canvas.drawCircle(const Offset(61, 62), 11, paint..color = Colors.white);
      final lock = Paint()
        ..color = const Color(0xFF8491A3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(57, 60, 8, 7), const Radius.circular(2)),
          lock..style = PaintingStyle.fill);
      canvas.drawArc(const Rect.fromLTWH(58, 55, 6, 10), math.pi, math.pi,
          false, lock..style = PaintingStyle.stroke);
    }
    canvas.restore();
  }

  void emblem(Canvas c, Color ink) {
    final p = Paint()
      ..color = ink
      ..isAntiAlias = true;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final t = title.toLowerCase();
    if (t.contains('code') &&
        !t.contains('scholar') &&
        !t.contains('polyglot')) {
      c.drawPath(
          Path()
            ..moveTo(31, 25)
            ..lineTo(23, 33)
            ..lineTo(31, 41),
          line);
      c.drawPath(
          Path()
            ..moveTo(49, 25)
            ..lineTo(57, 33)
            ..lineTo(49, 41),
          line);
      c.drawLine(const Offset(43, 23), const Offset(37, 43),
          line..color = unlocked ? Colors.white : ink);
    } else if (t.contains('started') || t.contains('builder')) {
      c.drawPath(
          Path()
            ..moveTo(39, 46)
            ..quadraticBezierTo(38, 30, 48, 21),
          line);
      c.drawPath(
          Path()
            ..moveTo(40, 34)
            ..cubicTo(40, 19, 48, 20, 55, 19)
            ..cubicTo(56, 31, 48, 36, 40, 34),
          p);
      c.drawPath(
          Path()
            ..moveTo(39, 39)
            ..cubicTo(25, 40, 25, 31, 24, 27)
            ..cubicTo(35, 26, 40, 31, 39, 39),
          p..color = Color.lerp(ink, Colors.white, .2)!);
    } else if (t.contains('roll') ||
        t.contains('warrior') ||
        t.contains('showed')) {
      c.drawPath(
          Path()
            ..moveTo(40, 17)
            ..cubicTo(44, 29, 56, 30, 53, 40)
            ..cubicTo(49, 53, 26, 51, 26, 38)
            ..cubicTo(25, 31, 32, 27, 33, 24)
            ..lineTo(35, 34)
            ..quadraticBezierTo(43, 28, 40, 17),
          p);
      c.drawPath(
          Path()
            ..moveTo(40, 32)
            ..quadraticBezierTo(52, 47, 40, 47)
            ..quadraticBezierTo(31, 44, 40, 32),
          p..color = const Color(0xFFFFEAA0));
    } else if (t.contains('spark')) {
      c.drawPath(
          polygon(const [
            Offset(42, 16),
            Offset(27, 35),
            Offset(38, 35),
            Offset(34, 50),
            Offset(53, 28),
            Offset(42, 28)
          ]),
          p);
    } else if (t.contains('star') ||
        t.contains('landing') ||
        t.contains('legend') ||
        t.contains('thinker')) {
      c.drawPath(star(const Offset(40, 33), 18, 9, 5), p);
      c.drawPath(
          Path()
            ..moveTo(34, 31)
            ..lineTo(39, 25)
            ..lineTo(44, 31),
          line
            ..color = Colors.white.withValues(alpha: .6)
            ..strokeWidth = 2);
    } else if (t.contains('arcade') || t.contains('champion')) {
      c.drawPath(
          Path()
            ..moveTo(29, 20)
            ..lineTo(51, 20)
            ..lineTo(49, 34)
            ..quadraticBezierTo(40, 46, 31, 34)
            ..close(),
          p);
      c.drawArc(const Rect.fromLTWH(23, 22, 12, 15), math.pi / 2, math.pi,
          false, line);
      c.drawArc(const Rect.fromLTWH(45, 22, 12, 15), -math.pi / 2, math.pi,
          false, line);
      c.drawLine(const Offset(40, 37), const Offset(40, 47), line);
      c.drawLine(const Offset(32, 48), const Offset(48, 48), line);
    } else if (t.contains('focused')) {
      c.drawCircle(const Offset(40, 34), 15, line);
      c.drawLine(const Offset(40, 34), const Offset(40, 25), line);
      c.drawLine(const Offset(40, 34), const Offset(48, 38), line);
      c.drawLine(const Offset(35, 15), const Offset(45, 15), line);
    } else if (t.contains('language') || t.contains('polyglot')) {
      c.drawCircle(const Offset(40, 33), 17, line);
      c.drawOval(const Rect.fromLTWH(32, 16, 16, 34), line..strokeWidth = 2);
      c.drawLine(const Offset(24, 33), const Offset(56, 33), line);
      c.drawArc(const Rect.fromLTWH(24, 21, 32, 14), 0, math.pi, false, line);
    } else if (t.contains('scholar') || t.contains('library')) {
      c.drawPath(
          Path()
            ..moveTo(40, 24)
            ..quadraticBezierTo(31, 19, 23, 23)
            ..lineTo(23, 44)
            ..quadraticBezierTo(31, 40, 40, 45)
            ..quadraticBezierTo(49, 40, 57, 44)
            ..lineTo(57, 23)
            ..quadraticBezierTo(49, 19, 40, 24)
            ..close(),
          p);
      c.drawLine(
          const Offset(40, 25),
          const Offset(40, 42),
          line
            ..color = Colors.white.withValues(alpha: .8)
            ..strokeWidth = 2);
    } else if (t.contains('challenger')) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(25, 21, 30, 27), const Radius.circular(4)),
          line);
      c.drawLine(const Offset(25, 29), const Offset(55, 29), line);
      c.drawPath(
          Path()
            ..moveTo(33, 38)
            ..lineTo(38, 43)
            ..lineTo(47, 34),
          line);
    } else {
      c.drawPath(
          polygon(const [
            Offset(40, 15),
            Offset(54, 28),
            Offset(47, 45),
            Offset(27, 47),
            Offset(29, 27)
          ]),
          p);
      c.drawCircle(const Offset(41, 29), 5,
          p..color = Colors.white.withValues(alpha: .85));
      c.drawPath(
          Path()
            ..moveTo(30, 43)
            ..lineTo(25, 51)
            ..lineTo(35, 47),
          line);
    }
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      title != old.title || color != old.color || unlocked != old.unlocked;
}
