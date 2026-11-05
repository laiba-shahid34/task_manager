import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Local notifications (reminders). Each task owns the ids  id*20 + 0..13
///   id*20       -> one-time or daily reminder
///   id*20 + d   -> weekly reminder for weekday d (1 = Mon ... 7 = Sun)
///   id*20 + 10..13 -> follow-ups if still not done (10 min, 1 hour, 1 day, 1 week)
class Notifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    _setLocalZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
    );
  }

  /// Picks the timezone that matches the phone (no extra plugin needed).
  static void _setLocalZone() {
    final now = DateTime.now();
    final offsetMs = now.timeZoneOffset.inMilliseconds;
    final abbr = now.timeZoneName;
    tz.Location? best;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      final zone = loc.timeZone(now.millisecondsSinceEpoch);
      if (zone.offset == offsetMs) {
        if (zone.abbreviation == abbr) {
          best = loc;
          break;
        }
        best ??= loc;
      }
    }
    tz.setLocalLocation(best ?? tz.UTC);
  }

  static String? lastError;

  /// Human-readable permission state, shown in Settings.
  static Future<String> status() async {
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notif = await impl?.areNotificationsEnabled();
      final exact = await impl?.canScheduleExactNotifications();
      return 'Notifications: ${notif == true ? "ON ✅" : "OFF ❌"}\n'
          'Exact alarms: ${exact == true ? "ON ✅" : "OFF ❌"}';
    } catch (e) {
      return 'Could not check: $e';
    }
  }

  /// Schedules a test reminder 10 seconds from now. Returns an error text or null.
  static Future<String?> scheduleTest(String sound) async {
    lastError = null;
    final when = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    Future<void> go(AndroidScheduleMode m) => _plugin.zonedSchedule(
          id: 999998,
          title: '⏰ Test reminder',
          body: 'Scheduled reminders are working!',
          scheduledDate: when,
          notificationDetails: _details(sound),
          androidScheduleMode: m,
        );
    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      try {
        await go(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e2) {
        lastError = '$e2';
      }
    }
    return lastError;
  }

  static Future<bool> requestPermissions() async {
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ok = await impl?.requestNotificationsPermission();
      await impl?.requestExactAlarmsPermission();
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static NotificationDetails _details(String sound) {
    AndroidNotificationDetails a;
    if (sound == 'silent') {
      a = const AndroidNotificationDetails(
        'reminders_silent',
        'Reminders (silent)',
        channelDescription: 'Silent task reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
      );
    } else if (sound == 'alarm') {
      a = AndroidNotificationDetails(
        'reminders_alarm',
        'Alarm reminders',
        channelDescription: 'Loud alarm that keeps ringing until you open or dismiss it',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        sound: const RawResourceAndroidNotificationSound('alarm'),
        additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT: repeat sound
        fullScreenIntent: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[0, 800, 400, 800, 400, 800]),
      );
    } else if (sound == 'default') {
      a = const AndroidNotificationDetails(
        'reminders_default',
        'Reminders (phone sound)',
        channelDescription: 'Task reminders with the phone default sound',
        importance: Importance.max,
        priority: Priority.high,
      );
    } else {
      a = AndroidNotificationDetails(
        'reminders_$sound',
        'Reminders ($sound)',
        channelDescription: 'Task reminders with a custom sound',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(sound),
      );
    }
    return NotificationDetails(android: a);
  }

  static Future<void> cancelFor(Task t) async {
    if (t.id == null) return;
    for (var k = 0; k <= 13; k++) {
      try {
        await _plugin.cancel(id: t.id! * 10 + k);
      } catch (_) {}
    }
  }

  static Future<void> schedule(Task t, String sound) async {
    if (t.id == null) return;
    await cancelFor(t);
    if (!t.hasReminder || t.isDone) return;

    final base = t.id! * 20;
    final now = DateTime.now();

    tz.TZDateTime? nextDue;

    if (t.repeat == Repeat.none) {
      if (t.dueAt.isBefore(now)) {
        // already overdue: keep nagging with the follow-ups that are still ahead
        await _followUps(base, t, tz.TZDateTime.from(t.dueAt, tz.local), sound);
        return;
      }
      nextDue = tz.TZDateTime.from(t.dueAt, tz.local);
      await _zoned(base, t, nextDue, null, sound);
    } else if (t.repeat == Repeat.daily) {
      var first = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          t.dueAt.hour, t.dueAt.minute);
      if (!first.isAfter(tz.TZDateTime.now(tz.local))) {
        first = first.add(const Duration(days: 1));
      }
      nextDue = first;
      await _zoned(base, t, first, DateTimeComponents.time, sound);
    } else {
      for (final wd in t.repeatDays) {
        var d = tz.TZDateTime(tz.local, now.year, now.month, now.day,
            t.dueAt.hour, t.dueAt.minute);
        for (var i = 0; i < 8; i++) {
          if (d.weekday == wd && d.isAfter(tz.TZDateTime.now(tz.local))) break;
          d = d.add(const Duration(days: 1));
        }
        await _zoned(base + wd, t, d, DateTimeComponents.dayOfWeekAndTime, sound);
        if (nextDue == null || d.isBefore(nextDue)) nextDue = d;
      }
    }

    if (nextDue != null) await _followUps(base, t, nextDue, sound);
  }

  /// "Still not done" reminders after the due time. They are cancelled
  /// automatically when the task is ticked (schedule() runs cancelFor first).
  static const _followDelays = <Duration>[
    Duration(minutes: 10),
    Duration(hours: 1),
    Duration(days: 1),
    Duration(days: 7),
  ];
  static const _followLabels = <String>[
    '10 minutes',
    '1 hour',
    '1 day',
    '1 week',
  ];

  static Future<void> _followUps(
      int base, Task t, tz.TZDateTime due, String sound) async {
    final nowTz = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < _followDelays.length; i++) {
      final when = due.add(_followDelays[i]);
      if (!when.isAfter(nowTz)) continue;
      await _zoned(
        base + 10 + i,
        t,
        when,
        null,
        sound,
        title: '🔔 Still pending: ${t.title}',
        body: 'This task is not completed yet (due ${_followLabels[i]} ago). Tap to open it.',
      );
    }
  }

  static Future<void> _zoned(int id, Task t, tz.TZDateTime when,
      DateTimeComponents? match, String sound,
      {String? title, String? body}) async {
    body ??= t.description.isEmpty ? 'Your task is due now ✨' : t.description;

    Future<void> go(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id: id,
          title: title ?? '⏰ ${t.title}',
          body: body,
          scheduledDate: when,
          notificationDetails: _details(sound),
          androidScheduleMode: mode,
          matchDateTimeComponents: match,
        );

    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      debugPrint('Exact schedule failed: $e');
      // Exact alarms not allowed -> fall back to the normal (less precise) one.
      try {
        await go(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e2) {
        lastError = '$e2';
        debugPrint('Schedule failed: $e2');
      }
    }
  }

  static Future<void> showNow(String sound) => _plugin.show(
        id: 999999,
        title: '💜 Test notification',
        body: 'Your reminders are working perfectly!',
        notificationDetails: _details(sound),
      );
}
