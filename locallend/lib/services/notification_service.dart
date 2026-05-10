import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _initialized = true;
  }

  Future<void> scheduleRentalEndingSoon({
    required int id,
    required String itemTitle,
    required DateTime lastDay,
  }) async {
    await init();
    final when = tz.TZDateTime.from(
      lastDay.subtract(const Duration(hours: 12)),
      tz.local,
    );
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      'Rental ending soon',
      'Your rental of "$itemTitle" ends tomorrow.',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rental_reminders',
          'Rental reminders',
          channelDescription: 'Warnings before a rental ends',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
