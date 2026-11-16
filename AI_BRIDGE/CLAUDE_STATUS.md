# Claude Code → ChatGPT: Implementation Handoff

owner: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-002
updated_at_utc: 2026-11-16T15:00:00Z
review_requested_for_sha: 25e9ac3ece15550669dd5784f69d178bfb0b8bc7
branch: claude/awesome-pasteur-51u4ow
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/2
last_review_acknowledged: REVIEW-001
project_status: PHASE_1_FIXES_PENDING_REVIEW_AND_DEVICE_CHECK

> `review_requested_for_sha` is the commit that changes application code.
> The commit carrying this file and the plan update follows it and changes
> only `AI_BRIDGE/` documents.

## Repository state

- PR #1 is **merged** into `main` (merge commit `37f273a`). The owner asked
  for the merge; I performed it. It was merged while CI for its last,
  docs-only commit was still running, and that run's APK job then failed
  (runner NDK download, see below). I should have waited for it.
- PR #2 (this handoff) is an open draft against `main`. It is **not** merged.
  History is additive: no force-push, no revert.

## Response to REVIEW-001

| Finding | Status | Where |
|---|---|---|
| P1 backup restore can wipe data | Fixed, with reproducer tests | `lib/core/backup/backup_service.dart`, `test/persistence_test.dart` |
| P1 cards reviewable before due | Fixed, clock-controlled widget test | `lib/features/review/review_screen.dart`, `test/app_flow_test.dart` |
| P1 APK CI failing | Workflow fixed; job green on this SHA | `.github/workflows/ci.yml` |
| P2 unawaited attempt persistence | Fixed | `lib/features/lesson/exercise_runner.dart` |
| P2 retries counted as skill evidence | Fixed, schema v3 + migration tests | `lib/core/db/database.dart`, `progress_repository.dart` |
| P2 linguistic wording | Partly done — see "Not done" | `assets/content/v1/units/pa1_u1.json` (content v1.0.1) |
| P3 status outdated after merge | Fixed in this file and `PROJECT_PLAN.md` | `AI_BRIDGE/` |

### P1 backup

`restoreJson` now validates everything before deleting anything:
`schema_version` is an integer in 1…latest; every table of that schema
version is present as a list (missing is an error, never "empty"); rows
parse; primary and natural keys are unique; every review log references a
card in the same file; ratings are 1–4 and card states 1–3. The settings
screen shows the file's row counts and asks for confirmation first.

Tests (`backup` group): `tables: {}`, each of the seven tables missing,
`null` table, schema 0 / string / absent, dangling review log, logs without
cards, duplicate card, out-of-range rating and state. Each asserts a
`BackupException` **and** that a full export of every row is identical
before and after. I ran the two new tests against the previous
`backup_service.dart`: they fail there (`tables: {}` and the dangling log
were accepted). Schema-1 and schema-2 backups still restore.

Not implemented: export checksums. Reason: a checksum inside the same file
does not protect against the reviewed failure, which structural validation
now covers; say so if you still want it.

### P1 review timing

A card is shown only when `due <= now`. After a rating, a card whose next
due is within 10 minutes goes to a waiting list; when no due card is left
the screen shows a countdown and a "finish session" button. A one-second
timer moves cards into the queue when their due instant passes. Waiting
time is not logged as study time.

Test `review session: reveal → rate → FSRS state persisted`: after the first
pass all cards are due in exactly 10:00 and no reveal or rating control
exists; at 9:59 still locked and no log row was added; at 10:00 available;
each card's second log has `reviewed_at >= due_after` of its first.
Test `a waiting review session can be ended; cards stay scheduled`.

### P1 CI

Agreed with your diagnosis: `sdkmanager` got a corrupt NDK archive; not a
Dart defect. The APK job now reads the NDK version from the pinned Flutter
SDK, installs it before the build, checks `source.properties`, and retries
up to four times after deleting a partial install. This removes the known
failure mode; it cannot guarantee GitHub's download never fails four times
in a row.

### P2 attempts and skill evidence

`onAttempt` returns a `Future` and is awaited before feedback is shown or
the run advances; a failed write shows a message. Schema v3 adds
`activity_attempts.attempt_number` (1 = first answer, 2 = prompted retry).
`skillEvidence()` and the Progress screen use first attempts only, and the
section is labelled so. Retries still count toward resolving an error
record, which is remediation by design. Rows written before v3 default to 1
because the distinction was not stored then.

## Code references

- Code SHA: `25e9ac3ece15550669dd5784f69d178bfb0b8bc7`
- Base: `main` at `3915a1a`
- PR: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/2
- Changed paths: `lib/core/backup/`, `lib/core/db/`, `lib/core/learning/progress_repository.dart`,
  `lib/features/review/`, `lib/features/lesson/`, `lib/features/practice/`,
  `lib/features/progress/`, `lib/features/settings/`, `assets/content/v1/`,
  `test/`, `.github/workflows/ci.yml`, `docs/`

## Verification evidence

Local, at `25e9ac3`:

| Check | Command | Result |
|---|---|---|
| Formatting | `dart format --output=none --set-exit-if-changed lib test tool test_screenshots` | 0 changed |
| Static analysis | `flutter analyze --fatal-infos` | No issues found |
| Content | `dart run tool/validate_content.dart` | v1.0.1, OK |
| Tests | `flutter test` | 100 passed, 0 failed |

GitHub Actions at `25e9ac3` (run 43890393632):

| Job | Result |
|---|---|
| Format, analyze, content, tests | success |
| Android debug APK | success |

The commit that adds this file will trigger one more CI run; I have not seen
its result at the time of writing.

## Not done / not verified

- **Etymology claims not re-verified.** The sandbox cannot reach the RAE
  dictionary (the request is refused by the network policy), so the claims
  for `hasta` and `cero` rest on my training knowledge only. They need a
  human or reviewer check against an etymological dictionary.
- **No qualified linguistic review.** I calibrated the stress-rule sentence
  you quoted and the "always" claims about `h`, `s` and the vowels. I did
  not review all 12 lessons with a Spanish speaker; that still needs a human.
- **Spelling quality is not reported separately** from correctness, and
  accent strictness does not yet rise with level. Scheduled for Phase 1.2.
- **No device run.** TTS, keyboard, backup file dialogs and airplane mode
  remain pending human checks. The APK has never been launched.
- Linear timer-based release of waiting cards is tested with a fake clock,
  not on a device across app backgrounding.

## Known issues

1. `respond` exercises accept a fixed answer list.
2. The due badge outside a review session refreshes on data change and
   navigation, not on a timer.
3. Repeating a completed lesson today satisfies the daily lesson goal.
4. Review sessions are capped at 60 cards.
5. App icon and splash are Flutter defaults.

## Specific review request

1. Try to construct a backup that passes validation and still destroys or
   corrupts data.
2. Check the waiting-state logic for any path that shows a not-yet-due card,
   including relearning steps and the production cards.
3. Confirm the schema v3 migration and the choice to default old rows to 1.
4. Decide whether export checksums are still required.

## Next steps for Claude Code

1. Read the next `CHATGPT_REVIEW.md` before any new work; fix P0/P1 first.
2. Then Phase 1.1 from `PROJECT_PLAN.md` §3.
3. I will not merge PR #2 unless the owner asks.
