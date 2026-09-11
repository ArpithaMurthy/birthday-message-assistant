import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:moments_remembered/models/birthday.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  Future<bool> requestPermission() async {
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return androidGranted ?? iosGranted ?? false;
  }

  Future<void> rescheduleAll(List<Birthday> birthdays) async {
    await _plugin.cancelAll();
    final now = DateTime.now();
    final reminders = <_Reminder>[];
    for (final birthday in birthdays) {
      final occurrence = birthday.nextOccurrence(now);
      for (final daysBefore in birthday.reminderDays) {
        final date = occurrence.subtract(Duration(days: daysBefore));
        final scheduled = tz.TZDateTime(tz.local, date.year, date.month, date.day, 9);
        if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) continue;
        reminders.add(_Reminder(birthday: birthday, occurrence: occurrence, daysBefore: daysBefore, scheduled: scheduled));
      }
    }
    reminders.sort((left, right) => left.scheduled.compareTo(right.scheduled));
    for (final reminder in reminders.take(60)) {
        final birthday = reminder.birthday;
        final occurrence = reminder.occurrence;
        final daysBefore = reminder.daysBefore;
        final id = Object.hash(birthday.id, occurrence.year, daysBefore) & 0x7fffffff;
        final timing = daysBefore == 0 ? 'today' : daysBefore == 1 ? 'tomorrow' : 'in $daysBefore days';
        await _plugin.zonedSchedule(
          id,
          '${birthday.name}\'s birthday is $timing',
          'Take a moment to prepare something thoughtful.',
          reminder.scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'birthday_reminders',
              'Birthday reminders',
              channelDescription: 'Reminders for upcoming birthdays',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: birthday.id,
        );
    }
  }
}

class _Reminder {
  const _Reminder({required this.birthday, required this.occurrence, required this.daysBefore, required this.scheduled});

  final Birthday birthday;
  final DateTime occurrence;
  final int daysBefore;
  final tz.TZDateTime scheduled;
}
