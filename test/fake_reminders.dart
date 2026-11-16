import 'package:espanol_pro/core/reminders/reminder_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Records every call so tests can assert exactly what would reach Android.
class FakeReminderPlatform implements ReminderPlatform {
  FakeReminderPlatform({this.zone = 'Asia/Dubai', this.enabled = true});

  String zone;
  bool enabled;
  bool grantOnRequest = true;
  bool throwOnSchedule = false;
  String? launch;
  void Function(String? payload)? onTap;

  final List<String> calls = [];
  final Map<int, tz.TZDateTime> pending = {};
  int permissionRequests = 0;

  @override
  Future<void> initialize({required void Function(String?) onTap}) async {
    this.onTap = onTap;
  }

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<bool> notificationsEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (grantOnRequest) enabled = true;
    return enabled;
  }

  @override
  Future<String> deviceTimeZone() async => zone;

  @override
  Future<void> scheduleDaily({
    required int id,
    required tz.TZDateTime first,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (throwOnSchedule) throw StateError('alarm service unavailable');
    calls.add('schedule $id ${first.location.name} $first');
    pending[id] = first;
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel $id');
    pending.remove(id);
  }

  int get schedules => calls.where((c) => c.startsWith('schedule')).length;
}
