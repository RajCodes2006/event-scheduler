import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/schedule_event.dart';

/// Android local reminders. Notifications remain entirely on the device.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static bool get supportsEventReminders => Platform.isAndroid;

  Future<void> initialize() async {
    if (_initialized || !Platform.isAndroid) return;

    try {
      timezone_data.initializeTimeZones();
      try {
        final localTimezone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
      } catch (error) {
        // A UTC fallback still represents the same absolute instant when
        // scheduling; use the native timezone when it is available.
        debugPrint('Daymark timezone lookup failed: $error');
        tz.setLocalLocation(tz.UTC);
      }

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_daymark'),
        ),
      );
      _initialized = true;
    } catch (error) {
      // Notification setup must never prevent the scheduler from opening.
      debugPrint('Daymark notification initialization failed: $error');
    }
  }

  /// Requests Android's notification permission when it has not been granted.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;

    try {
      await initialize();
      if (!_initialized) return false;

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;

      if (await android.areNotificationsEnabled() ?? false) return true;
      return await android.requestNotificationsPermission() ?? false;
    } catch (error) {
      debugPrint('Daymark notification permission request failed: $error');
      return false;
    }
  }

  Future<void> scheduleReminder(ScheduleEvent event) async {
    if (!Platform.isAndroid || event.id == null) return;

    try {
      await initialize();
      if (!_initialized) return;

      // Always remove the old reminder first. This also handles reminders
      // being switched off or an event being moved to the past.
      await _plugin.cancel(event.id!);
      if (event.reminderMinutesBefore <= 0) return;
      if (!event.startAt.isAfter(DateTime.now())) return;

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null ||
          !(await android.areNotificationsEnabled() ?? false)) {
        return;
      }

      final now = DateTime.now();
      final intendedReminder = event.startAt.subtract(
        Duration(minutes: event.reminderMinutesBefore),
      );
      final reminderIsStillAhead = intendedReminder.isAfter(now);
      final scheduledAt = reminderIsStillAhead
          ? intendedReminder
          : now.add(const Duration(seconds: 5));

      final body = reminderIsStillAhead
          ? 'Starts in ${_formatLeadTime(event.reminderMinutesBefore)}.'
          : 'Coming up soon.';

      await _plugin.zonedSchedule(
        event.id!,
        event.title,
        body,
        tz.TZDateTime.from(scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daymark_event_reminders',
            'Event reminders',
            channelDescription: 'Reminders for events in your Daymark schedule.',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: event.id.toString(),
      );
    } catch (error) {
      // A failed reminder should not roll back an otherwise-saved event.
      debugPrint('Could not schedule Daymark reminder: $error');
    }
  }

  Future<void> cancelReminder(int eventId) async {
    if (!Platform.isAndroid) return;

    try {
      await initialize();
      if (_initialized) await _plugin.cancel(eventId);
    } catch (error) {
      debugPrint('Could not cancel Daymark reminder: $error');
    }
  }

  /// Reconciles saved events with Android's pending reminder queue on launch.
  Future<void> syncReminders(List<ScheduleEvent> events) async {
    if (!Platform.isAndroid) return;

    try {
      await initialize();
      if (!_initialized) return;

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null ||
          !(await android.areNotificationsEnabled() ?? false)) {
        return;
      }

      final savedIds = events
          .where((event) => event.id != null)
          .map((event) => event.id!)
          .toSet();
      final pending = await _plugin.pendingNotificationRequests();
      for (final reminder in pending) {
        if (!savedIds.contains(reminder.id)) {
          await _plugin.cancel(reminder.id);
        }
      }

      for (final event in events) {
        await scheduleReminder(event);
      }
    } catch (error) {
      debugPrint('Could not sync Daymark reminders: $error');
    }
  }

  String _formatLeadTime(int minutes) {
    if (minutes >= 60 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return '$hours hour${hours == 1 ? '' : 's'}';
    }
    return '$minutes minute${minutes == 1 ? '' : 's'}';
  }
}
