import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'taskmate_channel';
  static const _channelName = 'TaskMate Notifications';
  static const _channelDesc = 'Alerts for tasks, messages, and server activity';
  static const _reminderHours = [8, 14, 20]; // 8AM, 2PM, 8PM

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
              playSound: true,
            ),
          );
    }

    _initialized = true;
  }

  // ── Permission ──────────────────────────────────────────────────────────────
  Future<bool> requestPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      final android =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Request notification permission (Android 13+)
      final notifGranted =
          await android?.requestNotificationsPermission() ?? false;

      // Request exact alarm permission (Android 12+)
      final exactGranted =
          await android?.requestExactAlarmsPermission() ?? false;

      return notifGranted && exactGranted;
    }
    return true;
  }

  /// Check if exact alarms are permitted (Android 12+)
  Future<bool> _canScheduleExactAlarms() async {
    if (!kIsWeb && Platform.isAndroid) {
      final android =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await android?.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  // ── Immediate notification ──────────────────────────────────────────────────
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Schedule task reminders ─────────────────────────────────────────────────
  Future<void> scheduleTaskReminders(TaskModel task) async {
    if (!task.hasAlarm) return;
    await cancelTaskReminders(task.id);

    final now = DateTime.now();
    final deadline = task.deadline;

    for (int daysOffset = 3; daysOffset >= 0; daysOffset--) {
      final day = deadline.subtract(Duration(days: daysOffset));

      for (int hourIndex = 0; hourIndex < _reminderHours.length; hourIndex++) {
        final hour = _reminderHours[hourIndex];
        final scheduledTime = DateTime(day.year, day.month, day.day, hour, 0);

        if (scheduledTime.isAfter(now)) {
          final notifId = _buildNotifId(task.id, daysOffset, hourIndex);
          final daysLabel =
              daysOffset == 0
                  ? 'Today'
                  : daysOffset == 1
                  ? 'Tomorrow'
                  : 'In $daysOffset days';

          await _scheduleNotification(
            id: notifId,
            title: '⏰ Task Reminder: ${task.title}',
            body:
                '$daysLabel at ${_formatHour(hour)} — Deadline: ${_formatDate(deadline)}',
            scheduledDate: scheduledTime,
          );
        }
      }
    }
  }

  Future<void> cancelTaskReminders(String taskId) async {
    for (int d = 0; d <= 3; d++) {
      for (int h = 0; h < 3; h++) {
        await _plugin.cancel(_buildNotifId(taskId, d, h));
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Private helpers ──────────────────────────────────────────────────────────
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Use exact alarm only if permitted, otherwise fall back to inexact
    final canExact = await _canScheduleExactAlarms();
    final scheduleMode =
        canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _buildNotifId(String taskId, int daysOffset, int hourIndex) {
    final base = taskId.hashCode.abs() % 100000;
    return base * 100 + daysOffset * 10 + hourIndex;
  }

  String _formatHour(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:00 $period';
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
