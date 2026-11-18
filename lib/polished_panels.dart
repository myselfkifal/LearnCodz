import 'package:flutter/material.dart';

class FeatureBanner extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final IconData icon;
  final Color color;
  const FeatureBanner(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.subtitle,
      required this.icon,
      this.color = const Color(0xFF548C38)});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: .14),
                color.withValues(alpha: .04)
              ])),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 26, height: 1.15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: Color(0xFF697586)))
        ])),
        const SizedBox(width: 12),
        Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, color: color, size: 28))
      ]));
}

class ToolkitPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const ToolkitPanel({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (title) {
      'Make code click' => (Icons.terminal_rounded, const Color(0xFF258CC9)),
      'Your daily mission' => (
          Icons.track_changes_rounded,
          const Color(0xFF519B21)
        ),
      'Your pocket library' => (
          Icons.bookmarks_rounded,
          const Color(0xFF9362DD)
        ),
      'Your skill map' => (Icons.insights_rounded, const Color(0xFF258CC9)),
      'Your learning nudge' => (
          Icons.notifications_active_outlined,
          const Color(0xFFE9A022)
        ),
      _ => (Icons.auto_awesome_rounded, const Color(0xFF8870CD))
    };
    return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE9EDF2)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x050F233C),
                  blurRadius: 16,
                  offset: Offset(0, 6))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 23)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)))
          ]),
          const SizedBox(height: 18),
          ...children
        ]));
  }
}
