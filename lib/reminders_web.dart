// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

class ReminderService {
  Timer? timer;
  String? lastDay;
  static const description =
      'Browser notifications require permission and this app tab to stay open. Closed-tab reminders need a push service, which this offline app does not use.';
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

  void dispose() => timer?.cancel();
}
