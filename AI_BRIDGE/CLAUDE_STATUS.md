# Claude Code → ChatGPT: Implementation Handoff

owner: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-004
updated_at_utc: 2026-11-16T20:15:00Z
review_requested_for_sha: 7b94f64902bb32cc2a59f213612b03798bed0b63
branch: feat/phase-1.1-foundation
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/3
last_review_acknowledged: REVIEW-005
previous_handoff: PHASE1-003 (code cd4abab)
project_status: PHASE_1_1_PART_A_REVIEW_005_FIXES_READY

> `review_requested_for_sha` is the last commit that changes application
> code. The commit carrying this file follows it and changes only
> `AI_BRIDGE/CLAUDE_STATUS.md`. PR #4 (reminders) has its own handoff on its
> own branch: `PHASE1-005`.

## Response to REVIEW-005 (PR #3 findings)

Fix commit: `7b94f64` (on top of `802e8cf`, a merge of `main` at `7b81634`
so the branch carries your review files unchanged).

### P2 — unrated study-time flush could lose time or race a rating — fixed

New `lib/core/learning/study_time_checkpoint.dart`. It is the only path by
which the review screen stores study time:

- **Serialised.** Ratings and flushes run strictly one after another on one
  future chain. Each computes its seconds from the acknowledged checkpoint
  inside its own turn, so a flush that arrives during an in-flight rating
  waits, then stores only the seconds after it.
- **Acknowledged only after success.** The checkpoint advances only after a
  successful write. A failed flush or a rolled-back rating leaves its seconds
  pending, and the next flush or rating stores them (retry). A failure in
  the middle of the queue does not block later writes.
- **The rating path** passes its seconds into the same SQLite transaction as
  the FSRS update (unchanged from Codex's `rateReview`), then acknowledges.

Tests:

- `test/study_time_checkpoint_test.dart` (8 tests):
  - injected write failure, then retry;
  - a rating after a failed flush carrying the unsaved seconds;
  - a failed rating acknowledging nothing;
  - background during a slow rating, and a rating during a slow flush (both race orders, total seconds exact);
  - a failure mid-queue not blocking later writes;
  - no negative time.
- `test/app_flow_test.dart`: `leaving the review screen at once still stores the time` (route change disposes the screen without a rating), plus the existing backgrounding test.

**Remaining limitation (documented, not hidden).** The final flush started
from `dispose` cannot be awaited. It is normally preceded by the lifecycle
flush when the app leaves the foreground, which is the path that runs
before Android kills a process. The database is app-wide and is not closed
by leaving the review screen, so that final write is not racing a closed
database. Closing the whole app is the exception.

### P3 — saved-phrase and legacy-backup semantics — made explicit

- Test: the same sentence saved from two lessons keeps one row, with its
  first source, date and note.
- The restore preview no longer shows "0 saved phrases" for a pre-v4 backup.
  It says the file predates «عباراتي» and current saved phrases stay. Test:
  `BackupService.summarize` omits tables absent from the file.
- `docs/DATABASE.md` states both policies.

### P2 — PR #4 handoff — addressed on PR #4's branch (`PHASE1-005`)

### P2 — native reminder delivery on a device — still pending

This needs the owner's phone. Nothing here claims it.

## Verification for `7b94f64`

Local:

| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool test_screenshots` | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| `dart run tool/validate_content.dart` | OK |
| `flutter test` | **140 passed**, 2 full runs |

GitHub Actions on `7b94f64` (run 43945882423):

| Job | Result |
|---|---|
| Format, analyze, content, tests | success |
| Android debug APK | success |

---

Everything below is the `PHASE1-003` handoff for the same PR, kept for
context.

## Acknowledgement of REVIEW-004

- PR #1 and PR #2 are merged (PR #2 merge `ef35c1e`). The previous version of
  this file still described PR #2 as an open draft and `PHASE1-002` as
  current; that was stale and is corrected.
- The REVIEW-002 fixes were written by Codex (`65324da`) and verified in
  REVIEW-003 and REVIEW-004. I did not author them.
- Owner-confirmed device checks, recorded in the REVIEW-004 addendum and now
  in `docs/`: (1) reviews and progress after relaunch, (2) backup export and
  restore, (3) offline use, (4) Spanish audio, (5) on-screen keyboard. This is
  owner testimony, not automated or reviewer-witnessed evidence. I will not
  ask for these again unless a change touches them or a regression appears.
- REVIEW-004 P2 "time on an opened, unrated card is not checkpointed" is
  addressed in this PR (below).
- Remaining Phase 1 gate: human review of the Spanish content. Content stays
  `author_reviewed`.

## This PR: Phase 1.1, part A

Base: `main` at `6f3ee26`. Commits, oldest first:

| SHA | Change |
|---|---|
| `5a3a5cf` | docs: reconcile project status with merged PR #2 and REVIEW-004 |
| `27cc6fc` | feat(phrases): saved phrases library with schema v4 migration |
| `adea039` | feat(review): live due counter and unrated-card study time |
| `244f3a8` | feat(brand): icon, adaptive icon and splash screen |
| `cd4abab` | docs: Phase 1.1 status, schema v4 and screenshots |

### Saved phrases («عباراتي»)

- **What you can save:** any Spanish sentence, via a bookmark on vocabulary headwords, example sentences, lesson grammar notes and the grammar reference.
- **New library tab:** search (accent- and case-insensitive; Spanish, Arabic, English, notes), audio, personal note, source lesson, date, and remove with undo.
- **Schema v4:** an additive `saved_phrases` table. `phrase_key` is the normalised Spanish text, not a content id, so records survive curriculum edits and the same sentence saved from two screens is one row.
- **Backups:** a v4 backup must contain the table. Rows are validated before anything is deleted (non-empty text, key matches text, known source kind, valid date, no duplicate ids or keys).
- **Kept, not wiped:** reset-progress and restoring a pre-v4 backup both leave saved phrases untouched.
- **No FSRS cards from saved phrases yet.** The reserved id scheme `phrase:<key>` is in `docs/DATABASE.md`.

### Live review counter

The Home and Practice due counts were computed only on rebuild, so they went stale on an idle dashboard. `dueSummaryProvider` now:

- sets one timer for the next card's due instant (no polling);
- exists only while a screen listens;
- recomputes on app resume.

### Unrated-card study time (REVIEW-004 P2)

Time on an opened but unrated review card is written when the app leaves the foreground and when the review screen closes. `_savedSeconds` advances before the write, so a later rating never counts the same seconds twice.

### App identity

- **Mark:** «ñ» from the bundled Inter Bold (OFL) in white on brand teal `#0E5E6F`.
- **Icons:** a vector adaptive icon with a monochrome layer (Android 13 themed icons), plus density PNGs for Android 7.
- **Splash:** the Android 12+ system splash and the legacy splash, each with a dark variant, plus a matching in-app loading screen.
- **Reproducible:** generated by `tool/brand/generate_android_icons.py`.

### Defects found by the new tests and fixed before push

1. `SavedPhrasesRepository.save` reported duplicates as newly saved. Drift's `insert` returns a row id even when the row is ignored; it now uses `insertReturningOrNull`.
2. The note dialog disposed its `TextEditingController` while the dialog was still animating out, which crashed. The dialog now owns its controller.

## Verification evidence

Local, at `cd4abab`:

| Check | Command | Result |
|---|---|---|
| Formatting | `dart format --output=none --set-exit-if-changed lib test tool test_screenshots` | 0 changed |
| Analysis | `flutter analyze --fatal-infos` | No issues |
| Content | `dart run tool/validate_content.dart` | OK |
| Tests | `flutter test` | **130 passed** (baseline 105), 3 runs |
| Drift | `dart run build_runner build` | identical to committed file |

GitHub Actions on `cd4abab` (run 43939088514):

| Job | Result |
|---|---|
| Format, analyze, content, tests | success |
| Android debug APK | success |

New tests: `test/saved_phrases_test.dart`, `test/due_counter_test.dart`, `test/branding_test.dart`. New widget tests in `test/app_flow_test.dart`:

- the counter turning live at the due instant with no database write;
- the saved-phrases UI (save, note, search, remove, undo);
- unrated review time stored on backgrounding, without double counting.

New migration and backup cases are in `test/persistence_test.dart` (v3 → v4 on a real file).

## Not verified

- **Icon, splash and the saved-phrases flow** have not been seen on a device. CI built the APK; nobody has installed this build.
- **Unrated review time** is tested with real elapsed time and simulated lifecycle events. A real process kill is not exercised.
- **Schema v4 on an existing install:** the owner's device database will migrate v3 → v4 on first launch. This is tested on a file, not yet on that device.

## Known issues

1. `respond` exercises accept a fixed answer list.
2. Review sessions are capped at 60 cards.
3. Saved phrases do not create FSRS cards yet (deliberate, see above).
4. Spelling quality is not yet reported separately from correctness (Phase 1.2).

## Specific review request

1. Saved-phrase identity: is the normalised Spanish text the right key? Is keeping phrases on reset and on pre-v4 restore the right call?
2. The live counter: any path where the count goes stale or a timer outlives its screen?
3. The unrated-time flush: any path that double-counts or loses time?
4. Backup validation for the new table.

## Next: Phase 1.1, part B (local reminders)

Implemented locally on `feat/phase-1.1-reminders`, stacked on this branch. It will be pushed as a separate PR with its own handoff. It adds:

- `flutter_local_notifications` (BSD-3), `timezone` and `flutter_timezone`;
- core-library desugaring;
- a boot receiver;
- an inexact daily alarm, so no exact-alarm permission.

It currently has 150 local tests passing. Kept separate because it adds native dependencies and Android permissions.

I will not merge either PR; merging is the owner's decision.
