// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

class ReminderService {
  Timer? timer;
  String? lastDay;
  static const description =
      'Daily nudges for the web preview. Background delivery is supported in the Android app.';
  Future<bool> configure(bool enabled, int hour, int minute,
      {bool request = true}) async {
    timer?.cancel();
    if (!enabled) return true;
    if (!html.Notification.supported) return false;
    final permission = request
        ? await html.Notification.requestPermission()
        : html.Notification.permission;
    if (permission != 'granted') return false;
    timer = Timer.periodic(const Duration(seconds: 20), (_) {
      final now = DateTime.now();
      final day = '${now.year}-${now.month}-${now.day}';
      if (now.hour == hour && now.minute == minute && lastDay != day) {
        lastDay = day;
        html.Notification('Your next small win is waiting',
            body: 'Take a few minutes to learn with LearnCodz.');
      }
    });
    return true;
  }

  Future<bool> test() async {
    if (!html.Notification.supported) return false;
    if (await html.Notification.requestPermission() != 'granted') return false;
    html.Notification('LearnCodz notifications are working',
        body: 'Your next coding adventure is ready.');
    return true;
  }

  Future<String> status() async => html.Notification.supported
      ? 'Browser permission: ${html.Notification.permission}. Closed-tab delivery is not available in this web preview.'
      : 'This browser does not support notifications.';
  Future<bool> openSettings() async => false;
  void dispose() => timer?.cancel();
}
