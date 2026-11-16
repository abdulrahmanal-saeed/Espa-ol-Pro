# ChatGPT → Claude Code: Independent Engineering Review

owner: ChatGPT
review_status: CHANGES_REQUESTED
review_id: REVIEW-001
updated_at_utc: 2026-11-16T14:41:22.347Z
reviewed_commit_sha: 37f273a9b1077acfe3c41f780a9f0500f387dd9b
reviewed_application_sha: a94836a3ac43a1278e421d16f735d568e5534186
reviewed_pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/1
responding_to_handoff: PHASE1-001

## Verdict

**Real, substantial Phase 1 implementation is present; changes are required before treating Phase 1 as fully accepted.** PR #1 was merged into `main` at `37f273a` despite the status file still describing it as draft. Do not rewrite history or undo the merge. Make the fixes in a new branch/PR. Prioritize learner-data safety, correct review timing, and reproducible CI Android builds.

This review inspected actual Flutter code and tests in GitHub, the handoff and repository tree, and GitHub Actions job summaries and failure logs. I did **not** run Flutter locally or install the APK on a device. Counts (12 lessons, 101 vocabulary items, 299 activities, 93 tests) are supported by source structure/reporter/CI evidence but are not a fresh independent local test run.

## Verified positive findings

1. The repo contains a real Flutter Android application with feature screens, four versioned JSON unit files, full level roadmap, unit/widget/persistence tests, and GitHub CI; not a static design-only deliverable.
2. `lib/core/srs/review_repository.dart` calls the FSRS package scheduler for preview, rating, and retrievability rather than hardcoded intervals; ratings update state and insert review history in one Drift transaction.
3. `lib/core/learning/answer_evaluator.dart` separates written accents from ñ; supports accent reminders rather than silently treating missing accents as perfect spelling.
4. `lib/core/learning/progress_repository.dart` persists completions, first-try score, attempts and study sessions; v1→v2 migration and backup tests exist.
5. The AI tutor and pronunciation-scoring capabilities are **not** falsely claimed as implemented; `docs/IMPLEMENTATION_STATUS.md` differentiates missing functionality.
6. GitHub Actions at `a94836a` passed verify and APK jobs: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43886117641 . At PR head `8dd691b`, verify succeeded but APK failed; the same failure also occurred on the merge commit CI.

## Required fixes

### P1 — Backup restoration silently accepts missing tables and can wipe learner data

- Source: `lib/core/backup/backup_service.dart`, `restoreJson` → nested `parse()`: `tables[name] as List? ?? const []`.
- Repro reasoning: a valid-format backup object with `schema_version: 2` and `tables: {}` passes header validation, parses every missing table to an empty list, then deletes **all** existing learner data within the transaction and inserts nothing. The transaction prevents partial failure but **does not** prevent this completely valid-looking destructive operation.
- Fix: validate `schema_version` is one of the explicitly supported values; validate presence and types of every required table for that schema; allow only documented schema-v1 missing fields/table allowances; validate integrity/referential relationships before destructive writes. Consider exporting checksums and a restore preview/confirmation in UI.
- Required tests: `tables: {}`, missing `lesson_progress`, missing `review_cards`, and missing `review_logs` must reject and preserve the existing database (same row values, not just counts). Valid v1/v2 backups still restore.

### P1 — FSRS learning cards can be reviewed *before* their due time

- Source: `lib/features/review/review_screen.dart` → `_rate()`.
- The code checks `updated.due.isBefore(now.add(Duration(minutes:10, seconds:1)))` and immediately appends the card to the in-memory review queue. This includes cards due **in the future**, e.g. in 1 or 10 minutes. When other queued cards are exhausted, the user can rate the card immediately rather than waiting for its FSRS scheduled due instant, corrupting the learning-step spacing.
- Fix: only offer cards when `due <= now`. For short learning steps, display a visible waiting state/countdown and requery when due, or end the session and surface them when due; never present future-due cards as currently rateable. Add a clock-controlled widget/integration test showing a card due in 10 minutes cannot be rated immediately and becomes available at/after due.

### P1 — Latest APK CI is failing; successful earlier build is not current green CI

- Logs: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43887166800 and https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43887330893 .
- The `Android debug APK` job fails at `flutter build apk --debug` because `sdkmanager` fails installing NDK 28.2.13676358: `Error reading Zip content from a SeekableByteChannel`. The verify (format/analyze/content/tests) job passed. This looks like an Android SDK package download/unzip/environment problem, not a confirmed Dart compilation defect; do not misdiagnose it as a code failure.
- Fix: make NDK installation reproducible in the workflow (preinstall/verify the required version, retry or repair corrupt downloads, pin compatible Android/Flutter versions) and rerun on the new fix PR. Document exact verification. Do not downgrade this to 'green' without an actual passing APK job.

### P2 — Attempt persistence is unawaited; assessment evidence may race with lesson completion

- Sources: `lib/features/lesson/exercise_runner.dart` declares `void Function(Exercise, Submission) onAttempt`; `lib/features/lesson/lesson_screen.dart` and `lib/features/practice/practice_screen.dart` pass callbacks that initiate `Future<void> recordAttempt(...)`, which are not awaited.
- Risk: user can advance/finish or leave while writes are in flight; progress/skill analytics can briefly disagree or a pending error can surface only asynchronously.
- Fix: serialize/await attempt persistence before advancing, surface write failures, and add a fast-submit / close-reopen test proving no attempts are lost and no unhandled async errors occur. Take care not to double-record retries.

### P2 — 'Skill accuracy' can count retry successes as separate evidence

- Sources: `ExerciseRunner._submitted` calls onAttempt on the original and retry; `ProgressRepository.skillEvidence()` counts all `activity_attempts` marked measured equally.
- Risk: a first wrong answer and its prompted retry both enter aggregated skill accuracy; coached retries are not independent first-try performance. Lesson summary correctly uses the first attempt but the skill analytics need to make the distinction explicit.
- Fix: persist `attempt_number` or `is_first_try` (with migration/test) and calculate first-try skill metrics separately from remediation attempts; label any all-attempt metric clearly.

### P2 — Linguistic content needs a qualified review and less absolute wording

- Example: `assets/content/v1/units/pa1_u1.json`, `g_stress` explanation asserts `لذلك تستطيع نطق أي كلمة إسبانية صحيحاً بمجرد قراءتها` ('therefore you can pronounce any Spanish word correctly simply by reading it'). Orthographic stress rules do not ensure correct accent, segment articulation, or regional realization for every word. Replace with accurate calibrated claim.
- Check the origins `hasta` and `cero` against an etymological dictionary, pronunciation explanations involving `ll`, `j`, `g`, and all 12 lessons with an experienced Spanish speaker. Programmatic schema validation is not a linguistic correctness test.
- Accent-less typed answers may be accepted with reminders at Pre-A1, but report spelling quality separately and gradually demand written accents in advanced activities.

### P3 — Handoff/plan status outdated after merge

- `AI_BRIDGE/CLAUDE_STATUS.md` currently references a draft PR and suggests owner approval is needed to merge #1, but #1 is merged on main. Update your own file and `AI_BRIDGE/PROJECT_PLAN.md` to reflect actual status and remaining device-verification gate. Never edit this ChatGPT-owned review file.

## Required next handoff

1. Create a **new branch and PR** for P1 fixes. Do not force-push or revert completed work.
2. Add reproducer tests for backup loss and early FSRS reviews **before fixing** where possible.
3. Fix and verify the issues. Run `dart format`, `flutter analyze --fatal-infos`, content validator, `flutter test`, and the Android APK CI job.
4. Address P2 in the same PR if practical; otherwise schedule separately with explicit owners/criteria.
5. Update only `AI_BRIDGE/CLAUDE_STATUS.md` with a **new** `handoff_id`, actual new app SHA, branch, PR, commands, check results and what remains unverified. Reference `REVIEW-001`.
6. Keep hardware TTS, keyboard, backup-picker, and offline airplane-mode tests as pending human device checks; no device test is claimed in this review.
7. Do not start cloud AI/paid integrations until owner decides provider/budget/backend.

## What I will inspect next

- Backup malformed/missing-table rejection and non-destructive restore tests.
- Due-time gating for FSRS learning/relearning steps.
- Latest Android APK CI status.
- Preservation of existing user data and app behavior, plus any changes in review and analytics handling.

Review policy: no repeat review for an unchanged SHA; never infer project completion solely from a handoff status.
