import 'package:timezone/timezone.dart' as tz;

import '../settings.dart';
import '../srs/review_repository.dart';

/// The operating-system side of local notifications. The real implementation
/// wraps `flutter_local_notifications`; tests use a fake. Nothing here ever
/// talks to a server: reminders are scheduled and shown on the device only.
abstract class ReminderPlatform {
  /// [onTap] receives the payload of a notification tapped while the app runs.
  Future<void> initialize({required void Function(String? payload) onTap});

  /// Payload of the notification that launched the app, if any.
  Future<String?> launchPayload();

  /// Whether the OS currently lets this app post notifications.
  Future<bool> notificationsEnabled();

  /// Shows the OS permission prompt where the OS has one (Android 13+).
  /// Returns whether notifications are allowed afterwards.
  Future<bool> requestPermission();

  /// IANA name of the device time zone, e.g. `Asia/Dubai`.
  Future<String> deviceTimeZone();

  /// Schedules a notification that repeats daily at [first]'s local time.
  Future<void> scheduleDaily({
    required int id,
    required tz.TZDateTime first,
    required String title,
    required String body,
    required String payload,
  });

  Future<void> cancel(int id);
}

enum ReminderState {
  /// The learner has not turned reminders on.
  off,

  /// Scheduled and the OS allows notifications.
  scheduled,

  /// Scheduled, but the OS blocks this app's notifications, so nothing
  /// will be shown until the learner allows them in system settings.
  blockedBySystem,

  /// The platform failed (e.g. plugin error). Reminders are not active.
  failed,
}

/// Routes a notification may open. Payloads are checked against this list,
/// so a notification can never navigate anywhere unexpected.
const reminderRoutes = {'/home', '/review'};

String? safeReminderRoute(String? payload) =>
    reminderRoutes.contains(payload) ? payload : null;

/// The next instant the reminder should fire: today at the chosen time if
/// that is still ahead, otherwise tomorrow. Built in the device's zone, so a
/// daylight-saving change keeps the wall-clock time (a time skipped by a
/// spring-forward is moved forward by the zone rules, never silently lost).
tz.TZDateTime nextReminderTime(tz.TZDateTime now, int hour, int minute) {
  var at = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!at.isAfter(now)) {
    at = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }
  return at;
}

/// Keeps exactly one daily reminder in line with the settings.
///
/// One fixed notification id, cancelled before every schedule, makes
/// duplicates impossible. [sync] is cheap to call often (launch, resume,
/// settings change): it reschedules only when the time zone or the chosen
/// time actually changed.
class ReminderService {
  ReminderService(this.platform, {required this.clock});

  final ReminderPlatform platform;
  final Clock clock;

  static const notificationId = 7001;
  static const title = 'وقت الإسبانية';
  static const body =
      'خطة اليوم جاهزة: مراجعاتك المستحقة ودرسك التالي في انتظارك.';

  /// What is currently scheduled, as `zone|minuteOfDay`, or null if nothing.
  String? _scheduled;

  Future<ReminderState> sync(AppSettings settings) async {
    try {
      if (!settings.reminderEnabled) {
        if (_scheduled != null || !_cancelledOnce) {
          await platform.cancel(notificationId);
          _cancelledOnce = true;
        }
        _scheduled = null;
        return ReminderState.off;
      }
      final zoneName = await platform.deviceTimeZone();
      final location = _location(zoneName);
      final signature = '${location.name}|${settings.reminderMinuteOfDay}';
      if (signature != _scheduled) {
        final now = tz.TZDateTime.from(clock(), location);
        await platform.cancel(notificationId);
        await platform.scheduleDaily(
          id: notificationId,
          first: nextReminderTime(
            now,
            settings.reminderHour,
            settings.reminderMinute,
          ),
          title: title,
          body: body,
          payload: '/home',
        );
        _scheduled = signature;
      }
      return await platform.notificationsEnabled()
          ? ReminderState.scheduled
          : ReminderState.blockedBySystem;
    } catch (_) {
      _scheduled = null;
      return ReminderState.failed;
    }
  }

  bool _cancelledOnce = false;

  /// Unknown zone names fall back to UTC rather than failing the schedule.
  static tz.Location _location(String name) {
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.UTC;
    }
  }
}
