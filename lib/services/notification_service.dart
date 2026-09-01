import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

/// Schedules local reminders for tasks with a future reminder time.
class NotificationService {
  NotificationService();

  static const _channelId = 'clearday_reminders';
  static const _channelName = 'Task reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    try {
      tz_data.initializeTimeZones();
      await _configureLocalTimeZone();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'ClearDay',
        appUserModelId: 'com.clearday.ClearDay',
        guid: '7c4e9a12-8b3f-4d6a-9e1c-2a5f8d0b4e71',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        windows: windowsSettings,
      );

      await _plugin.initialize(settings: initSettings);
      await _createAndroidChannel();
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return false;
    }

    try {
      if (!_initialized) {
        await initialize();
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.request();
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
        await android?.requestExactAlarmsPermission();
        return status.isGranted || status.isLimited;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncTaskReminders(List<Task> tasks) async {
    if (!_initialized) {
      return;
    }

    try {
      await _plugin.cancelAll();
      final now = DateTime.now();
      for (final task in tasks) {
        final reminder = task.reminderAt;
        if (task.isCompleted || reminder == null || !reminder.isAfter(now)) {
          continue;
        }
        await _schedule(task);
      }
    } catch (_) {}
  }

  Future<void> _schedule(Task task) async {
    final reminder = task.reminderAt;
    if (reminder == null) {
      return;
    }

    final when = tz.TZDateTime.from(reminder, tz.local);
    final id = notificationIdFor(task.id);
    final title = 'ClearDay reminder';
    final body = task.title;

    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        payload: task.id,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: task.id,
      );
    }
  }

  int notificationIdFor(String taskId) => taskId.hashCode & 0x7fffffff;

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders for tasks and chores',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      windows: WindowsNotificationDetails(),
    );
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Reminders for tasks and chores',
        importance: Importance.high,
      ),
    );
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }
}
