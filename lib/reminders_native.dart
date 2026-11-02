import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  final plugin = FlutterLocalNotificationsPlugin();
  static const description =
      'Optional daily Android notification at your chosen local time. Delivery can be delayed by battery settings.';
  Future<bool> configure(bool enabled, int hour, int minute,
      {bool request = true}) async {
    await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification')));
    if (!enabled) {
      await plugin.cancel(41);
      return true;
    }
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final allowed = request
        ? await android?.requestNotificationsPermission()
        : await android?.areNotificationsEnabled();
    if (allowed != true) return false;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(
        tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = tz.TZDateTime(
          tz.local, now.year, now.month, now.day + 1, hour, minute);
    }
    await plugin.zonedSchedule(
        41,
        'Your next small win is waiting',
        'Take a few minutes to learn with LearnCodz.',
        when,
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'daily_learning', 'Daily learning reminders',
                channelDescription: 'Your optional daily learning nudge')),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
    return true;
  }

  void dispose() {}
}
