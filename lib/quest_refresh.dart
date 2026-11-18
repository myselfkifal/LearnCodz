import 'lottie_effects.dart';
import 'package:flutter/material.dart';
import 'welcome_profile.dart';

class QuestPullRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final int avatar;
  const QuestPullRefresh(
      {super.key,
      required this.child,
      required this.onRefresh,
      this.avatar = 2});
  @override
  State<QuestPullRefresh> createState() => QuestPullRefreshState();
}

class QuestPullRefreshState extends State<QuestPullRefresh> {
  final indicator = GlobalKey<RefreshIndicatorState>();
  RefreshIndicatorStatus? status;
  Future<void> show() => indicator.currentState?.show() ?? Future<void>.value();
  @override
  Widget build(BuildContext context) {
    final refreshing = status == RefreshIndicatorStatus.refresh ||
        status == RefreshIndicatorStatus.snap;
    // Flutter enters drag even before a pull reaches the refresh threshold.
    final visible = refreshing || status == RefreshIndicatorStatus.armed;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Stack(children: [
      RefreshIndicator.noSpinner(
        key: indicator,
        onRefresh: () => Future.wait([
          widget.onRefresh(),
          Future<void>.delayed(Duration(milliseconds: reduced ? 100 : 700))
        ]),
        onStatusChange: (next) {
          if (mounted) {
            setState(() => status = next);
          }
        },
        child: widget.child,
      ),
      Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
              child: AnimatedContainer(
            key: const ValueKey('mascot-refresh-header'),
            duration: Duration(milliseconds: reduced ? 0 : 180),
            curve: Curves.easeOutCubic,
            height: visible ? 132 : 0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFEDFFD0), Color(0xFFD8F2BE)]),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28))),
            child: OverflowBox(
                minHeight: 100,
                maxHeight: 132,
                alignment: Alignment.bottomCenter,
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: visible ? 1 : 0),
                              duration:
                                  Duration(milliseconds: reduced ? 0 : 550),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) =>
                                  Transform.translate(
                                      offset: Offset(0, (1 - value) * 18),
                                      child: Transform.rotate(
                                          angle:
                                              reduced ? 0 : (1 - value) * -.18,
                                          child: child)),
                              child: refreshing
                                  ? const QuestLottie(
                                      animation: QuestAnimation.grow,
                                      size: 66,
                                      repeat: true)
                                  : QuestBuddy(
                                      avatar: widget.avatar, size: 66)),
                          const SizedBox(width: 16),
                          Flexible(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    refreshing
                                        ? 'Refreshing your journey…'
                                        : 'Release to refresh',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF24522C))),
                                const SizedBox(height: 7),
                                if (refreshing)
                                  const SizedBox(
                                      width: 130,
                                      child: LinearProgressIndicator(
                                          minHeight: 4,
                                          color: Color(0xFF52962C),
                                          backgroundColor: Colors.white60))
                                else
                                  const Text('A little refresh. Keep growing.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF5C7A48)))
                              ]))
                        ]))),
          )))
    ]);
  }
}
