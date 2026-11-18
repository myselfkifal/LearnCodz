import 'package:flutter/material.dart';
import 'quest_motion.dart';

class QuestNavigation extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelected;
  const QuestNavigation(
      {super.key,
      required this.selectedIndex,
      required this.labels,
      required this.icons,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
        top: false,
        child: SizedBox(
            height: 88,
            child: LayoutBuilder(
              builder: (context, constraints) => TweenAnimationBuilder<double>(
                tween: Tween(end: selectedIndex.toDouble()),
                duration: Duration(milliseconds: reduced ? 0 : 380),
                curve: Curves.easeInOutCubic,
                builder: (context, position, _) {
                  final center =
                      constraints.maxWidth * (position + .5) / labels.length;
                  return Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                        child: CustomPaint(painter: _NavigationCurve(center))),
                    Positioned(
                        left: center - 27,
                        top: 0,
                        child: ExcludeSemantics(
                            child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF5CAC25),
                                          Color(0xFF1C5B3E)
                                        ]),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x263D6C26),
                                          blurRadius: 12,
                                          offset: Offset(0, 5))
                                    ]),
                                child: AnimatedSwitcher(
                                    duration: Duration(
                                        milliseconds: reduced ? 0 : 160),
                                    child: Icon(icons[selectedIndex],
                                        key: ValueKey(selectedIndex),
                                        color: Colors.white,
                                        size: 27))))),
                    Row(
                        children: List.generate(
                            labels.length,
                            (i) => Expanded(
                                child: Semantics(
                                    label: labels[i],
                                    button: true,
                                    selected: i == selectedIndex,
                                    child: QuestPress(
                                        child: InkWell(
                                            overlayColor:
                                                const WidgetStatePropertyAll(
                                                    Colors.transparent),
                                            splashFactory:
                                                NoSplash.splashFactory,
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            onTap: () => onSelected(i),
                                            child: ExcludeSemantics(
                                                child: SizedBox(
                                                    height: 88,
                                                    child: Column(children: [
                                                      SizedBox(
                                                          height: 55,
                                                          child: Center(
                                                              child: Opacity(
                                                                  opacity: i ==
                                                                          selectedIndex
                                                                      ? 0
                                                                      : 1,
                                                                  child: Icon(
                                                                      icons[i],
                                                                      size: 25,
                                                                      color: const Color(
                                                                          0xFF82908A))))),
                                                      const SizedBox(height: 6),
                                                      Text(labels[i],
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: i ==
                                                                      selectedIndex
                                                                  ? FontWeight
                                                                      .w800
                                                                  : FontWeight
                                                                      .w500,
                                                              color: i ==
                                                                      selectedIndex
                                                                  ? const Color(
                                                                      0xFF367B29)
                                                                  : const Color(
                                                                      0xFF718078))),
                                                    ])))))))))
                  ]);
                },
              ),
            )));
  }
}

class _NavigationCurve extends CustomPainter {
  final double center;
  _NavigationCurve(this.center);
  @override
  void paint(Canvas canvas, Size size) {
    final top = Path()
      ..moveTo(0, 14)
      ..lineTo(center - 49, 14)
      ..cubicTo(center - 35, 14, center - 35, 59, center, 59)
      ..cubicTo(center + 35, 59, center + 35, 14, center + 49, 14)
      ..lineTo(size.width, 14);
    final fill = Path.from(top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = Colors.white);
    canvas.drawPath(
        top,
        Paint()
          ..color = const Color(0xFFE2EAE1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_NavigationCurve old) => old.center != center;
}
