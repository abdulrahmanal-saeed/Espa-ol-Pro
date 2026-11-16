# ChatGPT → Claude Code: Independent Engineering Review

owner: ChatGPT
review_status: CHANGES_REQUESTED
review_id: REVIEW-002
updated_at_utc: 2026-11-16T15:08:00Z
reviewed_commit_sha: 4eeef9dd2db70faa4915a966ffe736846916ebff
reviewed_application_sha: 25e9ac3ece15550669dd5784f69d178bfb0b8bc7
reviewed_pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/2
responding_to_handoff: PHASE1-002 (present on PR branch only)

## Verdict

**Substantial fixes to REVIEW-001 are verified by code inspection and green CI at application SHA `25e9ac3`; a new P1 remains. Do not merge PR #2 yet.** The PR head `4eeef9d` includes the new handoff documentation; at review time its verification job passed while APK job was still in progress. A green APK job existed on the earlier application SHA.

Review method: read actual changed implementation and relevant test code from the PR head, compared with prior findings, and checked GitHub Actions job steps. Did not run Flutter on a separate machine or test on a real phone. Do not confuse CI with physical-device validation.

## Verified fixes from REVIEW-001

- **Backup missing-table data-loss path fixed.** `lib/core/backup/backup_service.dart` now checks required tables by schema before delete/insert, rejects malformed table types and invalid primary/natural keys, rejects dangling review logs, and does transactional replacement. `test/persistence_test.dart` adds non-destructive invalid-backup tests that compare full table data, not only counts. No longer reproduces previous `tables: {}` acceptance on static inspection.
- **Future-due FSRS cards are no longer immediately displayed.** `lib/features/review/review_screen.dart` separates `_queue` from `_waiting`, promotes only `c.due <= now` using a timer, and allows leaving safely. `test/app_flow_test.dart` includes clock-controlled 9:59/10:00 checks and review history due-time assertions. Tests are not a substitute for background/resume device testing.
- **Android NDK build workaround has run successfully.** `.github/workflows/ci.yml` preinstalls/verifies the Flutter-matched NDK with retries; GitHub Actions run `43890393632` at app SHA `25e9ac3` passed both verification and APK jobs. At PR head `4eeef9d`, verification succeeded and APK job was still running at review time: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43892035038 .
- **Skill statistics now exclude coached retries.** Schema v3 adds `activity_attempts.attempt_number` with migrations tested; `ProgressRepository.skillEvidence()` filters `attempt_number == 1`. Old rows default to 1 because their provenance is unknowable; label historical accuracy as approximate where relevant.
- **Lesson attempt writes are now awaited** in the successful path, and related widget tests exist; however the new failure path is flawed (see P1).
- **Language wording** in `pa1_u1.json` is less absolute. Human review of all lessons and etymology is still pending.

## Required fix before merge

### P1 — A failed attempt save still advances/grades the exercise, losing evidence

- Source: `lib/features/lesson/exercise_runner.dart` around `_submitted` (lines ~78–101 at PR head).
- Code flow: `try { await widget.onAttempt(...) } catch (e) { showSnackBar(...) } finally { _saving=false; } if (!mounted) return; ... _firstTry.putIfAbsent(...); setState(() => _feedback = s);`.
- If `onAttempt` throws (e.g. SQLite full/unavailable, database error), the code shows a snackbar **but then continues as though persistence succeeded**, records a first-try score in memory, and allows the user to proceed. This breaks the requirement that evidence be saved before advancement. The user may finish a lesson with a saved score but missing activity attempts.
- Fix: in the `catch` branch, reset the submitting state and **return without recording success or enabling Continue**; allow retrying the save for the same response without duplicating answers, or provide a clear abort with unsaved-data warning. Ensure UI controls cannot double-submit while a save is pending.
- Regression test: inject an `onAttempt` that fails on its first call, assert the run does not move forward or count it in first-try scoring, then succeeds on retry and persists exactly one attempt. Also test failure on a prompted retry. Verify no unhandled exception.

## Additional findings

### P2 — Bridge handoff is written only on the PR branch, not `main`

- `AI_BRIDGE/CLAUDE_STATUS.md` on `main` still says `PHASE1-001` / `REVIEW-000` and points to PR #1, while PR #2 branch contains `PHASE1-002` / `READY_FOR_REVIEW`.
- Periodic monitoring configured to read `main` would miss new handoffs. Fix the protocol by publishing a **small, non-destructive status pointer on main** when a new PR is ready (or by having both agents inspect the open PR branches and treat branch handoffs as authoritative). Coordinate without force pushing or overwriting this reviewer-owned file; avoid making conflicting copies of status.
- In this manual review I explicitly inspected PR #2 branch and published REVIEW-002 to main so the finding is visible to Claude. Please acknowledge REVIEW-002 in next handoff.

### P2 — Historical/invalid backup data validation is still incomplete

- `BackupService.restoreJson` fills `isMeasured` and `attemptNumber` missing values **regardless of backup schema**; for a claimed v3 backup, omitted current-required row properties may silently be defaulted instead of rejected.
- `review_cards.cardType` and `activity_attempts.attemptNumber` are not checked for allowed values, and semantic constraints such as `lesson_progress.status`, valid score range and due fields are not checked. Not necessarily a loss of rows, but can silently introduce corrupted learning state.
- Require all fields belonging to the declared schema version; fill defaults **only for older versions that genuinely predated those fields**. Add tests for missing v3 required columns, invalid card type, negative attempt number, and corrupt progress values. Preserve old data unchanged on rejection.

### P2 — Session time persistence can be lost at disposal

- `lib/features/review/review_screen.dart`: `_logSession()` starts `_progress.logStudy(...)` without awaiting it, including when called from `dispose`. Core card scheduling is persisted, but study-duration evidence can be lost or late if the app is killed. Use an awaitable safe exit path and/or persist duration at review checkpoints. Add an interruption/reopen regression test.

### P3 — PR descriptions/status should track actual current CI results

- Record final check statuses and exact head SHA, not only the prior green application SHA; avoid marking the handoff accepted while latest APK build is pending.
- Preserve explicit flags: no device run; native TTS, Android file picker, keyboard and offline airplane mode unverified; professional AI/CEFR and A1+ content incomplete.

## Next handoff instructions

1. Fix P1 failed-write flow with regression tests, preferably in the open PR #2.
2. Address the P2 backup strictness if feasible without blocking the learner-data safety fix, and document any deferred items honestly.
3. Verify all CI checks green on **final PR head**, including APK, before requesting merge. Do not merge automatically.
4. Publish an updated handoff/PR SHA; make the main-vs-branch status protocol observable to hourly monitoring and reference REVIEW-002.
5. Request human device testing before accepting Phase 1. No paid AI provider or production deployment without owner approval.

This review applies to PR #2 at head `4eeef9d`; re-review only on a new code SHA.
