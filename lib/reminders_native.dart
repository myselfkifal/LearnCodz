import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  final plugin = FlutterLocalNotificationsPlugin();
  static const _settings = MethodChannel('learncodz/notifications');
  static const description = 'A small daily nudge, at a time you choose.';
  static const details = NotificationDetails(
      android: AndroidNotificationDetails(
          'learncodz_reminders_v2', 'LearnCodz learning reminders',
          channelDescription: 'Daily learning reminders and notification tests',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true));
  Future<void> initialize() async {
    await plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification')));
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
            'learncodz_reminders_v2', 'LearnCodz learning reminders',
            description: 'Daily learning reminders and notification tests',
            importance: Importance.high,
            playSound: true,
            enableVibration: true));
  }

  Future<bool> permission({bool request = true}) async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return (request
            ? await android?.requestNotificationsPermission()
            : await android?.areNotificationsEnabled()) ??
        false;
  }

  Future<bool> test() async {
    await initialize();
    if (!await permission()) return false;
    await plugin.show(
        42,
        'LearnCodz notifications are working',
        'Your next coding adventure is ready. This is a test notification.',
        details);
    return true;
  }

  Future<String> status() async {
    await initialize();
    if (!await permission(request: false)) {
      return 'Notifications are blocked. Open notification settings to allow LearnCodz.';
    }
    final pending = await plugin.pendingNotificationRequests();
    final channels = await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.getNotificationChannels();
    if (channels?.any((c) =>
            c.id == 'learncodz_reminders_v2' &&
            c.importance == Importance.none) ??
        false) {
      return 'The learning reminders channel is disabled. Enable it in notification settings.';
    }
    return pending.any((p) => p.id == 41)
        ? 'Notifications allowed. Your daily reminder is queued.'
        : 'Notifications allowed. No daily reminder is queued yet.';
  }

  Future<bool> openSettings() async =>
      await _settings.invokeMethod<bool>('openSettings') ?? false;
  Future<bool> configure(bool enabled, int hour, int minute,
      {bool request = true}) async {
    await initialize();
    if (!enabled) {
      await plugin.cancel(41);
      return true;
    }
    if (!await permission(request: request)) return false;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(
          tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      throw StateError(
          'Could not read device time zone. Check the phone date and time settings.');
    }
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = tz.TZDateTime(
          tz.local, now.year, now.month, now.day + 1, hour, minute);
    }
    await plugin.zonedSchedule(41, 'Your next small win is waiting',
        'Take a few minutes to learn with LearnCodz.', when, details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
    return (await plugin.pendingNotificationRequests()).any((p) => p.id == 41);
  }

  void dispose() {}
}
