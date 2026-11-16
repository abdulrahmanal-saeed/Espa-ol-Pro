# Claude Code → ChatGPT: Implementation Handoff

owner: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-005
updated_at_utc: 2026-11-16T20:20:00Z
review_requested_for_sha: 68adae7fdda173b053ffc07f70522f887d4f5105
branch: feat/phase-1.1-reminders
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/4
base: feat/phase-1.1-foundation (PR #3) — stacked, merge after PR #3
last_review_acknowledged: REVIEW-005
project_status: PHASE_1_1_PART_B_READY_FOR_REVIEW__DEVICE_CHECK_PENDING

> This file on the PR #4 branch describes **PR #4 only**. PR #3's handoff is
> `PHASE1-004` on `feat/phase-1.1-foundation`. `review_requested_for_sha` is
> the last commit that changes application code on this branch: the merge
> that brings PR #3's REVIEW-005 fix into the reminders work.

## Response to REVIEW-005 (PR #4 findings)

- **P2 — no separate handoff:** this file is PR #4's own handoff.
- **P2 — native delivery unverified on Android:** still true. Nothing here
  claims device delivery. The checklist is below; it needs the owner's
  phone.
- PR #4 stays stacked on PR #3 and must not be merged before PR #3.
  Merging this branch's history is additive; there was no force-push.

## What PR #4 contains

Daily local study reminder. Reminder commits: `1544b52` (feature), `e4343da`
(docs), `405ec84` (plugin pin). `72c09d7` and its revert `09480a7` are a
failed `compileSdk 37` attempt, kept in history as is (no force-push).

- **Settings → «التذكير اليومي»:** on/off (off by default) and a time picker.
- **Local only.** `flutter_local_notifications` 22.3.3 (BSD-3), `timezone` (BSD-2), `flutter_timezone` (Apache-2.0). Nothing goes to a server.
- **Inexact daily alarm** (`inexactAllowWhileIdle`), so no exact-alarm permission. Android may deliver it a few minutes late; the UI says so.
- **No duplicates.** One fixed id (`7001`), cancelled before every schedule. The service reschedules only when the zone or the chosen time changes.
- **Re-synced** on launch, on every resume and on settings changes. A time-zone change therefore reschedules it, and the wall-clock time is kept across daylight-saving changes.
- **Survives restarts.** The boot receiver (`ScheduledNotificationBootReceiver`, not exported) restores it after a reboot or app update. New permission: `RECEIVE_BOOT_COMPLETED`. `POST_NOTIFICATIONS` is requested once, when the learner turns reminders on.
- **OS-blocked state:** the schedule is kept, Settings explains the situation, and offers the permission prompt plus the system-settings path.
- **Taps** open Home, both while running and from a cold start, through an allow-list (`/home`, `/review`).
- **Failure-safe:** a plugin failure never blocks startup, and Settings shows "could not schedule".

### Why 22.3.3 and not 23.x

23.x depends on `androidx.core 1.19`, which needs `compileSdk 37`. The APK
job failed with Flutter's default 36. Installing `platforms;android-37` on
the runner failed because no package exists under that name; the build
hinted at a "37.1" minor-version scheme. 22.3.3, the latest 22.x, compiles
against 36 with the same API, so the app stays on Flutter's default toolchain.

## Verification

Local, at `68adae7`:

| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool test_screenshots` | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| `flutter test` | **160 passed**: PR #3's 140 plus 20 reminder tests; 2 full runs |

GitHub Actions:

| Head | Tests job | APK job |
|---|---|---|
| `405ec84` (plugin pin) | success | **success** (run 43943864128) |
| `68adae7` (merge of PR #3 fix) | success | **failure**: `Gradle threw an error while downloading artifacts from the network`, 6 s into the build |

The `68adae7` failure is a dependency download error on the runner. That
merge changes Dart and test files only; the Gradle files are identical to
`405ec84`, which built. **The commit carrying this file re-runs CI. I have
not seen that result at the time of writing.** Treat the APK as unverified
until that run is green.

Reminder tests:

- `test/reminders_test.dart` (fake platform recording every call):
  - next-fire time, month/year rollover, and the Madrid daylight-saving change;
  - exactly one schedule across repeated syncs, and cancel-before-schedule;
  - rescheduling in the new zone after a time-zone change;
  - off cancels, and leftovers are cleared once on a fresh start;
  - the OS-blocked state, failure and retry, and unknown-zone fallback;
  - the route allow-list, and settings persistence with corrupt-value fallback.
- `test/app_flow_test.dart`:
  - turning it on asks once, schedules one and persists;
  - resume does not reschedule;
  - turning it off cancels;
  - the blocked-notification notice and allow flow;
  - taps navigate, and unknown routes are ignored.

## Not verified — device checklist for the owner

None of this has run on a phone. After PR #3 and PR #4 are merged:

1. Turn the reminder on → Android asks for notification permission once → allow.
2. Set the time 3–5 minutes ahead, lock the phone → the notification arrives (possibly a few minutes late).
3. Swipe the app away, wait for the notification, tap it → the app opens on Home.
4. Restart the phone → the reminder still arrives the next day.
5. Deny notifications in system settings → Settings shows the explanation.
6. Turn the reminder off → nothing arrives.

## Specific review request

1. Permission and manifest footprint: is anything broader than needed?
2. Any path that can create a second schedule, or leave one after "off"?
3. Cold-start tap handling and the route allow-list.

I will not merge either PR; merging is the owner's decision.
