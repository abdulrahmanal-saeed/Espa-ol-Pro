import 'dart:async';

import 'package:espanol_pro/core/reminders/reminder_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Stops a fake platform call immediately before it returns or mutates its
/// alarm state. Each gate belongs to the next call of that operation.
class ReminderGate {
  final _entered = Completer<void>();
  final _resume = Completer<void>();

  Future<void> get entered => _entered.future;
  void release() => _resume.complete();
  void fail() => _resume.completeError(StateError('platform call failed'));

  Future<void> pause() {
    _entered.complete();
    return _resume.future;
  }
}

/// Records every call so tests can assert exactly what would reach Android.
class FakeReminderPlatform implements ReminderPlatform {
  FakeReminderPlatform({this.zone = 'Asia/Dubai', this.enabled = true});

  String zone;
  bool enabled;
  bool grantOnRequest = true;
  bool throwOnSchedule = false;
  bool throwAfterSchedule = false;
  ReminderGate? scheduleGate;
  ReminderGate? cancelGate;
  ReminderGate? permissionCheckGate;
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
  Future<bool> notificationsEnabled() async {
    final allowed = enabled;
    final gate = permissionCheckGate;
    permissionCheckGate = null;
    if (gate != null) await gate.pause();
    return allowed;
  }

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
    final gate = scheduleGate;
    scheduleGate = null;
    if (gate != null) await gate.pause();
    calls.add('schedule $id ${first.location.name} $first');
    pending[id] = first;
    if (throwAfterSchedule) throw StateError('alarm service response lost');
  }

  @override
  Future<void> cancel(int id) async {
    final gate = cancelGate;
    cancelGate = null;
    if (gate != null) await gate.pause();
    calls.add('cancel $id');
    pending.remove(id);
  }

  int get schedules => calls.where((c) => c.startsWith('schedule')).length;
}
