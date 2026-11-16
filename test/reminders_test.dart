import 'package:espanol_pro/core/reminders/reminder_service.dart';
import 'package:espanol_pro/core/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'fake_reminders.dart';
import 'support.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late FakeReminderPlatform platform;
  late FakeClock clock;
  late ReminderService service;
  const on = AppSettings(reminderEnabled: true, reminderMinuteOfDay: 19 * 60);

  setUp(() {
    platform = FakeReminderPlatform();
    // 09:00 UTC = 13:00 in Dubai.
    clock = FakeClock(DateTime.utc(2026, 3, 10, 9));
    service = ReminderService(platform, clock: clock.call);
  });

  group('next reminder time', () {
    tz.Location dubai() => tz.getLocation('Asia/Dubai');

    test('later today when the time is still ahead', () {
      final now = tz.TZDateTime(dubai(), 2026, 3, 10, 13);
      final at = nextReminderTime(now, 19, 0);
      expect(
        [at.year, at.month, at.day, at.hour, at.minute],
        [2026, 3, 10, 19, 0],
      );
    });

    test('tomorrow when the time has passed or is exactly now', () {
      final passed = nextReminderTime(
        tz.TZDateTime(dubai(), 2026, 3, 10, 20),
        19,
        0,
      );
      expect([passed.day, passed.hour], [11, 19]);
      final exact = nextReminderTime(
        tz.TZDateTime(dubai(), 2026, 3, 10, 19),
        19,
        0,
      );
      expect([exact.day, exact.hour], [11, 19]);
    });

    test('rolls over month and year ends', () {
      final at = nextReminderTime(
        tz.TZDateTime(dubai(), 2026, 12, 31, 23),
        7,
        30,
      );
      expect(
        [at.year, at.month, at.day, at.hour, at.minute],
        [2027, 1, 1, 7, 30],
      );
    });

    test('keeps the wall-clock time across a daylight-saving change', () {
      // Madrid springs forward on 2026-03-29 at 02:00 → 03:00.
      final madrid = tz.getLocation('Europe/Madrid');
      final before = tz.TZDateTime(madrid, 2026, 3, 28, 22);
      final at = nextReminderTime(before, 19, 0);
      expect([at.day, at.hour, at.minute], [29, 19, 0]);
      expect(at.timeZoneOffset, const Duration(hours: 2));
    });

    test('a time skipped by spring-forward still fires that day', () {
      final madrid = tz.getLocation('Europe/Madrid');
      final at = nextReminderTime(
        tz.TZDateTime(madrid, 2026, 3, 28, 22),
        2,
        30,
      );
      expect(at.day, 29);
      expect(at.isAfter(tz.TZDateTime(madrid, 2026, 3, 28, 22)), isTrue);
    });
  });

  group('service', () {
    test(
      'turning reminders on schedules exactly one, at the chosen time',
      () async {
        expect(await service.sync(on), ReminderState.scheduled);
        expect(platform.schedules, 1);
        final at = platform.pending[ReminderService.notificationId]!;
        expect(at.location.name, 'Asia/Dubai');
        expect([at.day, at.hour, at.minute], [10, 19, 0]);
      },
    );

    test(
      'repeated syncs never create duplicates or reschedule needlessly',
      () async {
        for (var i = 0; i < 5; i++) {
          await service.sync(on);
        }
        expect(platform.schedules, 1);
        expect(platform.pending.length, 1);
      },
    );

    test('every schedule is preceded by a cancel of the same id', () async {
      await service.sync(on);
      await service.sync(on.copyWith(reminderMinuteOfDay: 8 * 60));
      final id = ReminderService.notificationId;
      expect(platform.calls[0], 'cancel $id');
      expect(platform.calls[1], startsWith('schedule $id'));
      expect(platform.calls[2], 'cancel $id');
      expect(platform.calls[3], startsWith('schedule $id'));
      expect(platform.pending.length, 1);
      expect(platform.pending[id]!.hour, 8);
    });

    test('a time-zone change reschedules in the new zone', () async {
      await service.sync(on);
      platform.zone = 'Europe/Madrid';
      await service.sync(on);
      expect(platform.schedules, 2);
      final at = platform.pending[ReminderService.notificationId]!;
      expect(at.location.name, 'Europe/Madrid');
      expect(at.hour, 19);
    });

    test('turning reminders off cancels them', () async {
      await service.sync(on);
      expect(
        await service.sync(on.copyWith(reminderEnabled: false)),
        ReminderState.off,
      );
      expect(platform.pending, isEmpty);
    });

    test(
      'a fresh start with reminders off clears any leftover schedule',
      () async {
        platform.pending[ReminderService.notificationId] = tz.TZDateTime.now(
          tz.UTC,
        );
        await service.sync(const AppSettings());
        expect(platform.pending, isEmpty);
        // ...but does not keep calling cancel on every later sync.
        final calls = platform.calls.length;
        await service.sync(const AppSettings());
        expect(platform.calls.length, calls);
      },
    );

    test(
      'OS-blocked notifications are reported, schedule kept for later',
      () async {
        platform.enabled = false;
        expect(await service.sync(on), ReminderState.blockedBySystem);
        expect(platform.pending.length, 1);
        platform.enabled = true;
        expect(await service.sync(on), ReminderState.scheduled);
        expect(platform.schedules, 1);
      },
    );

    test(
      'a platform failure is reported and retried on the next sync',
      () async {
        platform.throwOnSchedule = true;
        expect(await service.sync(on), ReminderState.failed);
        platform.throwOnSchedule = false;
        expect(await service.sync(on), ReminderState.scheduled);
        expect(platform.schedules, 1);
      },
    );

    test('an unknown zone name falls back to UTC instead of failing', () async {
      platform.zone = 'Mars/Olympus_Mons';
      expect(await service.sync(on), ReminderState.scheduled);
      expect(
        platform.pending[ReminderService.notificationId]!.location.name,
        tz.UTC.name,
      );
    });
  });

  group('notification routes', () {
    test('only known screens can be opened from a notification', () {
      expect(safeReminderRoute('/home'), '/home');
      expect(safeReminderRoute('/review'), '/review');
      expect(safeReminderRoute('/settings'), isNull);
      expect(safeReminderRoute('https://example.com'), isNull);
      expect(safeReminderRoute(null), isNull);
    });
  });

  group('settings', () {
    test('reminder settings persist through the database', () async {
      final db = memoryDb();
      final repo = SettingsRepository(db);
      expect((await repo.load()).reminderEnabled, isFalse);
      await repo.save(
        const AppSettings(
          reminderEnabled: true,
          reminderMinuteOfDay: 7 * 60 + 45,
        ),
      );
      final s = await repo.load();
      expect(s.reminderEnabled, isTrue);
      expect([s.reminderHour, s.reminderMinute], [7, 45]);
      await db.close();
    });

    test('corrupt reminder values fall back to defaults', () {
      for (final bad in ['-1', '1440', 'soon', '']) {
        final s = AppSettings.fromMap({'reminderMinuteOfDay': bad});
        expect(s.reminderMinuteOfDay, 19 * 60, reason: bad);
      }
      expect(
        AppSettings.fromMap({'reminderEnabled': 'yes'}).reminderEnabled,
        isFalse,
      );
    });
  });
}
