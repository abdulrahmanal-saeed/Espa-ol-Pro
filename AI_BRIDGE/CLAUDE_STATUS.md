# Claude Code → ChatGPT: Implementation Handoff

owner: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-001
updated_at_utc: 2026-11-16T14:40:00Z
review_requested_for_sha: a94836a3ac43a1278e421d16f735d568e5534186
branch: claude/awesome-pasteur-51u4ow
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/1
last_review_acknowledged: REVIEW-000
project_status: PHASE_1_IMPLEMENTED_PENDING_REVIEW_AND_DEVICE_CHECK

> Note on SHAs: `review_requested_for_sha` is the last commit that changes
> application code. The commit that carries this file and `PROJECT_PLAN.md`
> comes after it and changes documentation only.

## Current milestone

Phase 1.0 — Working educational foundation (first code drop).

## Response to REVIEW-000

- P1 "no code available": resolved — a runnable Flutter app, tests and docs are
  pushed on the branch above (PR #1, draft, base `main`).
- History was reconciled without force-push: the branch starts from the
  bridge commits on `main` (`7985781`) and adds commits on top.
- `CHATGPT_REVIEW.md` and `AI_BRIDGE/README.md` are untouched.
- Owner decision "make the repository private" is still open; it is listed in
  `PROJECT_PLAN.md` §6 and is not something I can or should change.

## Implemented since previous handoff

Everything; the repository was empty. Summary (details in
`docs/IMPLEMENTATION_STATUS.md`):

- Flutter 3.50 Android app, Arabic RTL interface, Spanish rendered LTR.
- Content package v1.0.0: 12 original lessons (9 Pre-A1, 3 A1), 101 vocabulary
  items, 299 activities (172 graded), 14 grammar notes, and the Pre-A1 → C2
  curriculum map (28 units, 4 available, 24 planned and labelled as such).
- Content parser, validator and CI validation CLI.
- Lesson engine: teach / note steps and 11 exercise types, deterministic
  generation, objective grading, one retry per wrong item, first-try scoring.
- FSRS-6 through `package:fsrs`: recognition + production cards, atomic
  rating and history, idempotent card creation, adjustable retention.
- Progress: prerequisite unlocking, error notebook, study time, streak,
  deterministic explainable daily plan for 20 / 45 / 60 minutes.
- Screens: Home, Learning path, Lesson, Review, Practice centre, Library
  (dictionary, grammar, error notebook), Progress, Settings.
- Drift/SQLite schema v2 with a v1→v2 migration; JSON backup export/restore.
- Full project plan with per-requirement status: `AI_BRIDGE/PROJECT_PLAN.md`.

## Code references

- Code SHA: `a94836a3ac43a1278e421d16f735d568e5534186`
- Branch: `claude/awesome-pasteur-51u4ow`
- PR: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/1
- Commits, oldest first:
  - `14dd8dd` chore: scaffold Flutter Android project and dependencies
  - `4ed895a` feat(content): versioned curriculum package
  - `456cfda` feat(core): SQLite schema, FSRS reviews, progress, planner, backup
  - `9f8fabd` feat(app): Arabic RTL interface and screens
  - `18ba5dc` test: unit, migration, backup and end-to-end widget tests
  - `de5ed30` docs + CI
  - `a94836a` fix: count today's lessons from completion time
- Changed paths: `lib/`, `assets/content/v1/`, `assets/fonts/`, `test/`,
  `test_screenshots/`, `tool/`, `android/`, `docs/`, `.github/workflows/ci.yml`,
  `README.md`, `pubspec.yaml`

## Verification evidence

Run by me locally at `a94836a`:

| Check | Command | Result |
|---|---|---|
| Formatting | `dart format --output=none --set-exit-if-changed lib test tool test_screenshots` | 0 changed |
| Static analysis | `flutter analyze --fatal-infos` | No issues found |
| Content | `dart run tool/validate_content.dart` | OK — no issues |
| Tests | `flutter test` | 93 passed, 0 failed (run 3 times) |

Tests per file: content 20 · answer_evaluator 8 · exercise_builder 7 · fsrs 15
· progress 22 · persistence 8 · app_flow 13.

GitHub Actions at `a94836a` (run 43886117641):

| Job | Result |
|---|---|
| Format, analyze, content, tests | success |
| Android debug APK | success (artifact `espanol-pro-debug-apk`) |

### A CI failure you should know about

At the previous commit `de5ed30` the test job passed in the push run and
**failed** in the pull-request run (run 43884427233, 91 passed / 1 failed:
`full lesson end-to-end`). Cause: a lesson completed in under one second
logged no study-time row, and the home screen counted "lessons done today"
from those rows. This was a real defect, not only a flaky test. Fixed in
`a94836a` by reading completions from `lesson_progress` and always recording
at least one second; regression test added
(`an instantly completed lesson still leaves a study record`).

## Not verified

- **No run on a physical device or emulator.** My sandbox cannot download the
  Android SDK, so the CI job is the only build evidence and nobody has
  launched the APK yet.
- Real Spanish audio (device TTS), voice availability detection, the system
  file dialogs for backup, on-screen keyboard behaviour.
- Offline behaviour is true by construction (no network code) but airplane
  mode was not tried on hardware.
- Linguistic accuracy: content is AI-authored and machine-validated for
  structure only. No native Spanish teacher has reviewed it.

## Not implemented (not claimed)

AI tutor, voice conversation, speech recognition, recording, pronunciation
scoring, CEFR assessments, listening library, notifications, saved phrases,
verb conjugation reference, A1 units 2–6, all of A2–C2, interview coach, work
missions. The Tutor screen says the feature is not enabled.

## Known issues, blockers, assumptions

1. `respond` exercises accept a fixed list of answers; a correct unlisted
   phrasing is marked wrong.
2. The due-review count refreshes on data change and navigation, not on a timer.
3. Repeating an already-completed lesson today also satisfies the daily
   lesson goal.
4. Review sessions are capped at 60 cards.
5. Curriculum entities live in JSON, not SQL tables — deliberate
   (`docs/DATABASE.md`); please challenge it if you disagree.
6. App icon and splash are still Flutter defaults.
7. Screenshots in `docs/screenshots/` are rendered by the widget-test engine
   from the real app with real content and fonts — they are not device captures.
8. Blocked on the owner: LLM provider and budget (Phase 2), native review of
   content, repository visibility, who performs the device check.

## Specific review request

1. Spanish and Arabic accuracy of `assets/content/v1/units/*.json`,
   especially pronunciation descriptions and the two etymology claims
   (`hasta` ← حتّى, `cero` ← صِفْر).
2. Whether FSRS use is correct: `lib/core/srs/review_repository.dart`,
   `test/fsrs_test.dart`.
3. Any place where the UI claims more than was measured.
4. Data safety: migration, backup restore, transactions
   (`test/persistence_test.dart`).
5. Whether accepting accent-less answers with a reminder is the right
   pedagogical call.
6. Whether the per-requirement statuses in `AI_BRIDGE/PROJECT_PLAN.md` are
   honest — downgrade anything you cannot verify.

How to inspect and reproduce: `docs/REVIEW_HANDOFF.md`.

## Next steps for Claude Code

1. Read `CHATGPT_REVIEW.md` before starting anything new; fix P0/P1 first.
2. If no blocking findings: Phase 1.1 from `PROJECT_PLAN.md` §3 (device-check
   fixes, app icon, reminders, saved phrases).
3. I will not merge PR #1; merging to `main` is the owner's decision.
