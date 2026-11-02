import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'language_courses.dart';
import 'quest_widgets.dart';

class LanguageMark extends StatelessWidget {
  final StudyLanguage language;
  const LanguageMark({super.key, required this.language});
  @override
  Widget build(BuildContext context) {
    if (language == StudyLanguage.java) {
      return const SizedBox(
          width: 62,
          height: 62,
          child: Stack(alignment: Alignment.center, children: [
            Icon(Icons.local_cafe_outlined, size: 46, color: Color(0xFF1682C0)),
            Positioned(
                top: 0,
                child: Icon(Icons.waves, size: 28, color: Color(0xFFF27A25)))
          ]));
    }
    if (language == StudyLanguage.python) {
      return SizedBox(
          width: 62,
          height: 62,
          child: Stack(children: [
            Positioned(
                left: 5,
                top: 3,
                child: Container(
                    width: 38,
                    height: 33,
                    decoration: BoxDecoration(
                        color: const Color(0xFF3776AB),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                            padding: EdgeInsets.all(7),
                            child: CircleAvatar(
                                radius: 2, backgroundColor: Colors.white))))),
            Positioned(
                right: 5,
                bottom: 3,
                child: Container(
                    width: 38,
                    height: 33,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFD343),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                            padding: EdgeInsets.all(7),
                            child: CircleAvatar(
                                radius: 2, backgroundColor: Colors.white)))))
          ]));
    }
    return SizedBox(
        width: 62,
        height: 62,
        child: CustomPaint(
            painter: _HexPainter(language == StudyLanguage.c
                ? const Color(0xFF8054BC)
                : const Color(0xFF2275B4)),
            child: Center(
                child: Text(language == StudyLanguage.c ? 'C' : 'C++',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: language == StudyLanguage.c ? 36 : 25,
                        fontWeight: FontWeight.w900)))));
  }
}

class _HexPainter extends CustomPainter {
  final Color color;
  _HexPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      final x = size.width / 2 + math.cos(angle) * size.width * .47,
          y = size.height / 2 + math.sin(angle) * size.height * .47;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HexPainter old) => color != old.color;
}

class PracticeTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const PracticeTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE5E5ED))),
          child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                        width: 54,
                        height: 56,
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(icon, color: color, size: 30)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(subtitle,
                              style: const TextStyle(
                                  color: Color(0xFF6C6C74),
                                  fontSize: 12,
                                  height: 1.4))
                        ])),
                    const Icon(Icons.chevron_right, color: Color(0xFF73737B))
                  ])))));
}

class ProgressSummary extends StatelessWidget {
  final int passed, total, xp, streak;
  const ProgressSummary(
      {super.key,
      required this.passed,
      required this.total,
      required this.xp,
      required this.streak});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(children: [
        Expanded(
            child: Column(children: [
          SizedBox(
              width: 130,
              height: 130,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: total == 0 ? 0 : passed / total,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFE9E9ED),
                        color: questLime)),
                Text('${total == 0 ? 0 : (passed / total * 100).round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 32))
              ])),
          const SizedBox(height: 16),
          const Text('Course Progress',
              style: TextStyle(fontSize: 12, color: Colors.black54))
        ])),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          line(Icons.bolt_rounded, '$xp XP', const Color(0xFFFFC800)),
          line(Icons.workspace_premium_rounded, 'Level ${xp ~/ 100 + 1}',
              const Color(0xFFFFC800)),
          line(Icons.local_fire_department_rounded, '$streak Day Streak',
              const Color(0xFFFF7900))
        ]))
      ]));
  Widget line(IconData icon, String text, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))
      ]));
}

class CodePanel extends StatelessWidget {
  final String code;
  const CodePanel({super.key, required this.code});
  @override
  Widget build(BuildContext context) {
    final tokens = RegExp(
            r'("[^"\n]*"|\x27[^\x27\n]*\x27|\b(?:int|double|float|return|if|else|for|while|def|print|class|public|static|void|final|var|String|std)\b|\b\d+\b)')
        .allMatches(code);
    final spans = <TextSpan>[];
    var end = 0;
    for (final token in tokens) {
      spans.add(TextSpan(text: code.substring(end, token.start)));
      final text = token.group(0)!;
      spans.add(TextSpan(
          text: text,
          style: TextStyle(
              color: text.startsWith('"') || text.startsWith("'")
                  ? const Color(0xFF3D9300)
                  : int.tryParse(text) != null
                      ? const Color(0xFF118CA0)
                      : const Color(0xFFAA28B0),
              fontWeight: FontWeight.w700)));
      end = token.end;
    }
    spans.add(TextSpan(text: code.substring(end)));
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: const Color(0xFFF6F5FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBE9F0))),
        child: SelectableText.rich(TextSpan(children: spans),
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Color(0xFF25252D),
                height: 1.7)));
  }
}
