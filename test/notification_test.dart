import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quizquest/reminders_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  var allowed = true, queued = false;
  final calls = <MethodCall>[];
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    allowed = true;
    queued = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          return true;
        case 'requestNotificationsPermission':
        case 'areNotificationsEnabled':
          return allowed;
        case 'pendingNotificationRequests':
          return queued
              ? [
                  {
                    'id': 41,
                    'title': 'Reminder',
                    'body': 'Learn',
                    'payload': null
                  }
                ]
              : [];
        case 'getNotificationChannels':
          return [];
        case 'zonedSchedule':
          queued = true;
          return null;
        case 'cancel':
          queued = false;
          return null;
        default:
          return null;
      }
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_timezone'),
            (call) async => 'Asia/Karachi');
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
      'Notification test requests permission and uses visible high-priority channel',
      () async {
    expect(await ReminderService().test(), true);
    expect(
        calls.any((c) => c.method == 'requestNotificationsPermission'), true);
    final show = calls.firstWhere((c) => c.method == 'show');
    expect(show.arguments['id'], 42);
    expect(show.arguments['platformSpecifics']['channelId'],
        'learncodz_reminders_v2');
  });
  test('Denied permission sends nothing and reports blocked state', () async {
    allowed = false;
    final service = ReminderService();
    expect(await service.test(), false);
    expect(calls.any((c) => c.method == 'show'), false);
    expect(await service.status(), contains('blocked'));
  });
  test(
      'Daily schedule is queued without exact alarm permission and can be cancelled',
      () async {
    final service = ReminderService();
    expect(await service.configure(true, 19, 15), true);
    expect(await service.status(), contains('queued'));
    expect(calls.any((c) => c.method == 'requestExactAlarmsPermission'), false);
    expect(await service.configure(false, 19, 15), true);
    expect(queued, false);
  });
}
