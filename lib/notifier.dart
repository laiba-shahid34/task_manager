import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Local notifications (reminders).
///
/// Every task owns a block of 100 ids: base = taskId * 100
///   base + 0        -> one-time or daily reminder
///   base + 1..7     -> weekly reminder for weekday d (1 = Mon ... 7 = Sun)
///   base + 10..69   -> "still not done" nags, one every [nagMinutes] minutes
///                      after the due time, until the task is completed.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse r) {
  Notifier.handleBackground(r);
}

class Notifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channel = MethodChannel('task_manager/system');

  static const int _slot = 100;
  static const int _nagStart = 10;
  static const int _maxNags = 60;
  static const String actionDone = 'done';
  static const String actionStop = 'stop';

  /// Minutes between "still pending" reminders. 0 = no nagging.
  static int nagMinutes = 10;

  /// How many nag alarms each task may keep scheduled (Android allows ~500
  /// alarms per app, AppState lowers this when there are many tasks).
  static int perTaskNags = _maxNags;

  /// Called when the user taps "Done" on a notification (app is opened).
  static void Function(int taskId)? onDone;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _setLocalZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
  }

  static void _onResponse(NotificationResponse r) {
    final id = int.tryParse(r.payload ?? '');
    if (id == null) return;
    if (r.actionId == actionStop) {
      _cancelNags(id);
    } else if (r.actionId == actionDone) {
      onDone?.call(id);
    }
  }

  /// Runs in a background isolate when the app is closed ("Stop" button).
  static Future<void> handleBackground(NotificationResponse r) async {
    final id = int.tryParse(r.payload ?? '');
    if (id == null) return;
    if (r.actionId == actionStop) await _cancelNags(id);
  }

  /// If the app was started by pressing "Done" on a notification.
  static Future<int?> launchedWithDone() async {
    try {
      final d = await _plugin.getNotificationAppLaunchDetails();
      final r = d?.notificationResponse;
      if (d?.didNotificationLaunchApp == true &&
          r != null &&
          r.actionId == actionDone) {
        return int.tryParse(r.payload ?? '');
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _cancelNags(int taskId) async {
    final base = taskId * _slot;
    for (var k = 0; k < _maxNags; k++) {
      try {
        await _plugin.cancel(id: base + _nagStart + k);
      } catch (_) {}
    }
  }

  /// Wipes every scheduled reminder (used before re-creating them all).
  static Future<void> cancelEverything() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Asks Android to stop restricting this app's battery use, otherwise some
  /// phones kill the alarms when the app is closed.
  static Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod('batterySettings');
    } catch (e) {
      debugPrint('batterySettings: $e');
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('appSettings');
    } catch (e) {
      debugPrint('appSettings: $e');
    }
  }

  static Future<void> _setLocalZone() async {
    try {
      final dynamic info = await FlutterTimezone.getLocalTimezone();
      final String name = info is String ? info : info.identifier as String;
      tz.setLocalLocation(tz.getLocation(name));
      return;
    } catch (e) {
      debugPrint('flutter_timezone failed: $e');
    }
    _guessLocalZone();
  }

  /// Fallback: picks the timezone that matches the phone's offset.
  static void _guessLocalZone() {
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

  static const List<AndroidNotificationAction> _actions = [
    AndroidNotificationAction(actionDone, '✅ Done', showsUserInterface: true),
    AndroidNotificationAction(actionStop, '🔕 Stop'),
  ];

  static NotificationDetails _details(String sound, {bool actions = false}) {
    final acts = actions ? _actions : null;
    AndroidNotificationDetails a;
    if (sound == 'silent') {
      a = AndroidNotificationDetails(
        'reminders_silent',
        'Reminders (silent)',
        channelDescription: 'Silent task reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: false,
        actions: acts,
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
        actions: acts,
      );
    } else if (sound == 'default') {
      a = AndroidNotificationDetails(
        'reminders_default',
        'Reminders (phone sound)',
        channelDescription: 'Task reminders with the phone default sound',
        importance: Importance.max,
        priority: Priority.high,
        actions: acts,
      );
    } else {
      a = AndroidNotificationDetails(
        'reminders_$sound',
        'Reminders ($sound)',
        channelDescription: 'Task reminders with a custom sound',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(sound),
        actions: acts,
      );
    }
    return NotificationDetails(android: a);
  }

  static Future<void> cancelFor(Task t) async {
    if (t.id == null) return;
    final base = t.id! * _slot;
    for (var k = 0; k <= 7; k++) {
      try {
        await _plugin.cancel(id: base + k);
      } catch (_) {}
    }
    await _cancelNags(t.id!);
  }

  static tz.TZDateTime _nextTime(DateTime ref, int hour, int minute, {int? weekday}) {
    var d = tz.TZDateTime(tz.local, ref.year, ref.month, ref.day, hour, minute);
    for (var i = 0; i < 15; i++) {
      if (d.isAfter(ref) && (weekday == null || d.weekday == weekday)) return d;
      d = tz.TZDateTime(tz.local, d.year, d.month, d.day + 1, hour, minute);
    }
    return d;
  }

  static Future<void> schedule(Task t, String sound) async {
    if (t.id == null) return;
    await cancelFor(t);
    if (!t.hasReminder || t.isDone) return;

    final base = t.id! * _slot;
    final now = DateTime.now();
    DateTime anchor; // the moment the task was/is due; nags count from here

    if (t.repeat == Repeat.none) {
      anchor = t.dueAt;
      if (t.dueAt.isAfter(now)) {
        await _zoned(base, t, tz.TZDateTime.from(t.dueAt, tz.local), null, sound,
            main: true);
      }
    } else {
      // start counting from the due date if it is still ahead, otherwise now
      final ref = t.dueAt.isAfter(now)
          ? t.dueAt.subtract(const Duration(seconds: 1))
          : now;
      tz.TZDateTime? nextDue;
      if (t.repeat == Repeat.daily) {
        final first = _nextTime(ref, t.dueAt.hour, t.dueAt.minute);
        nextDue = first;
        await _zoned(base, t, first, DateTimeComponents.time, sound, main: true);
      } else {
        for (final wd in t.repeatDays) {
          final d = _nextTime(ref, t.dueAt.hour, t.dueAt.minute, weekday: wd);
          await _zoned(base + wd, t, d, DateTimeComponents.dayOfWeekAndTime, sound,
              main: true);
          if (nextDue == null || d.isBefore(nextDue)) nextDue = d;
        }
      }
      // a missed occurrence keeps nagging; otherwise nag after the next one
      anchor = t.dueAt.isBefore(now) ? t.dueAt : (nextDue ?? t.dueAt);
    }

    await _nags(base, t, anchor, sound);
  }

  /// "Still not done" reminders: one every [nagMinutes] minutes after the due
  /// time. They are cancelled when the task is ticked (schedule() runs
  /// cancelFor first) or when "Stop" is pressed on a notification.
  static Future<void> _nags(
      int base, Task t, DateTime anchor, String sound) async {
    final iv = nagMinutes;
    if (iv <= 0) return;
    final now = DateTime.now();
    var k = 1;
    if (anchor.isBefore(now)) {
      k = now.difference(anchor).inSeconds ~/ (iv * 60) + 1;
    }
    if (anchor.add(Duration(minutes: iv * k)).difference(now).inSeconds < 5) k++;

    final count = perTaskNags.clamp(1, _maxNags);
    for (var i = 0; i < count; i++, k++) {
      final late = Duration(minutes: iv * k);
      await _zoned(
        base + _nagStart + i,
        t,
        tz.TZDateTime.from(anchor.add(late), tz.local),
        null,
        sound,
        title: '🔔 Still pending: ${t.title}',
        body: 'Not completed yet - overdue by ${_human(late)}. '
            'Tick it as done to stop these reminders.',
      );
    }
  }

  static String _human(Duration d) {
    if (d.inDays >= 1) return '${d.inDays} day${d.inDays == 1 ? '' : 's'}';
    if (d.inHours >= 1) {
      final m = d.inMinutes % 60;
      return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
    }
    return '${d.inMinutes} min';
  }

  static Future<void> _zoned(int id, Task t, tz.TZDateTime when,
      DateTimeComponents? match, String sound,
      {String? title, String? body, bool main = false}) async {
    body ??= t.description.isEmpty ? 'Your task is due now ✨' : t.description;

    Future<void> go(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id: id,
          title: title ?? '⏰ ${t.title}',
          body: body,
          scheduledDate: when,
          notificationDetails: _details(sound, actions: true),
          androidScheduleMode: mode,
          matchDateTimeComponents: match,
          payload: '${t.id}',
        );

    // The due-time reminder uses an alarm-clock alarm: the most reliable type,
    // it also fires in Doze mode and when the app is closed.
    final modes = <AndroidScheduleMode>[
      if (main) AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];
    for (final m in modes) {
      try {
        await go(m);
        return;
      } catch (e) {
        debugPrint('Schedule ($m) failed: $e');
        lastError = '$e';
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
