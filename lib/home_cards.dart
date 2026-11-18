import 'package:flutter/material.dart';
import 'achievement_badge.dart';
import 'quest_widgets.dart';
import 'welcome_profile.dart';

class JourneyCard extends StatelessWidget {
  final String title, language;
  final int completed, total, avatar;
  final VoidCallback onTap;
  const JourneyCard(
      {super.key,
      required this.title,
      required this.language,
      required this.completed,
      required this.total,
      required this.avatar,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF173D38), Color(0xFF102E36)]),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x20143530),
                    blurRadius: 22,
                    offset: Offset(0, 10))
              ]),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(children: [
                const Positioned(
                    right: -35,
                    top: -35,
                    child: CircleAvatar(
                        radius: 85, backgroundColor: Color(0xFF234D45))),
                const Positioned(
                    right: 100,
                    top: 20,
                    child: Icon(Icons.auto_awesome,
                        color: Color(0xFF89C97A), size: 22)),
                Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text('$language PATH',
                                    style: const TextStyle(
                                        color: Color(0xFFDBF0C3),
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w800))),
                            const Spacer(),
                            Text('${(completed / total * 100).round()}%',
                                style: const TextStyle(
                                    color: Color(0xFFB7F18B),
                                    fontWeight: FontWeight.w800))
                          ]),
                          const SizedBox(height: 18),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      const Text('YOUR NEXT CHAPTER',
                                          style: TextStyle(
                                              fontSize: 10,
                                              letterSpacing: 1.2,
                                              color: Color(0xFFA4C5BC))),
                                      const SizedBox(height: 7),
                                      Text(title,
                                          style: const TextStyle(
                                              fontSize: 25,
                                              height: 1.15,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white)),
                                      const SizedBox(height: 10),
                                      Text(
                                          '$completed of $total chapters complete',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFBCD3CC)))
                                    ])),
                                const SizedBox(width: 10),
                                QuestBuddy(avatar: avatar, size: 82)
                              ]),
                          const SizedBox(height: 20),
                          LinearProgressIndicator(
                              value: completed / total,
                              color: const Color(0xFFADDF78),
                              backgroundColor:
                                  Colors.white.withValues(alpha: .12),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(8)),
                          const SizedBox(height: 20),
                          QuestButton(
                              label: 'Continue Learning',
                              color: const Color(0xFF95DC46),
                              onPressed: onTap),
                        ]))
              ]))));
}

class HomeStat extends StatelessWidget {
  final String label, value;
  final bool streak;
  const HomeStat(
      {super.key,
      required this.label,
      required this.value,
      this.streak = false});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
          color: streak ? const Color(0xFFFFF6EB) : const Color(0xFFF4F0FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color:
                  streak ? const Color(0xFFFFE8CE) : const Color(0xFFE8DFFF))),
      child: Row(children: [
        SizedBox(
            width: 44,
            height: 48,
            child: AchievementBadge(
                title: streak ? 'Showed Up' : 'First Spark',
                color:
                    streak ? const Color(0xFFFF9B29) : const Color(0xFFAA7AF0),
                unlocked: true)),
        const SizedBox(width: 9),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 25, height: 1.15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF697180)))
        ]))
      ]));
}

class DailyMissionRow extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onTap;
  final IconData icon;
  const DailyMissionRow(
      {super.key,
      required this.title,
      required this.done,
      required this.onTap,
      required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
          color: done ? const Color(0xFFF2F9E9) : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                  color: done
                      ? const Color(0xFFDDEDCB)
                      : const Color(0xFFE9EDF1))),
          child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color:
                                done ? Colors.white : const Color(0xFFF2F5FA),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(icon,
                            size: 21,
                            color:
                                done ? questGreen : const Color(0xFF70829C))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 8),
                    Icon(
                        done
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        color: done ? questGreen : const Color(0xFF9CAABA),
                        size: 21)
                  ])))));
}
