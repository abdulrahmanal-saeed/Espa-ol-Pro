import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_service.dart';

/// Android implementation on top of `flutter_local_notifications` (BSD-3).
///
/// Uses an INEXACT daily alarm: a study nudge does not need minute
/// precision, and this avoids the exact-alarm permissions Android 14
/// restricts. Android may shift delivery by some minutes to save battery.
class PluginReminderPlatform implements ReminderPlatform {
  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static const _channel = AndroidNotificationDetails(
    'study_reminder',
    'تذكير الدراسة اليومي',
    channelDescription: 'تذكير واحد يومياً في الوقت الذي تختاره.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: 'ic_launcher_monochrome',
  );

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher_monochrome'),
      ),
      onDidReceiveNotificationResponse: (r) => onTap(r.payload),
    );
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details!.notificationResponse?.payload;
  }

  @override
  Future<bool> notificationsEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<String> deviceTimeZone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  Future<void> scheduleDaily({
    required int id,
    required tz.TZDateTime first,
    required String title,
    required String body,
    required String payload,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: first,
    notificationDetails: const NotificationDetails(android: _channel),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    payload: payload,
  );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
