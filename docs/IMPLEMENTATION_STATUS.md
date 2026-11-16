# Implementation status

Four states are kept strictly apart: **implemented and tested**, **implemented
but not verified**, **not implemented**, **blocked**. Exact commit references
for the current handoff are in [`AI_BRIDGE/CLAUDE_STATUS.md`](../AI_BRIDGE/CLAUDE_STATUS.md).

Milestone: **Phase 1 — Working educational foundation** (first reviewable drop).

## Implemented and covered by automated tests

| Area | Evidence |
|---|---|
| Arabic RTL shell, Spanish LTR text, 5-tab navigation + settings | `app_flow_test`: RTL/LTR assertions, all tabs render |
| Light / dark theme, in-app text size; no overflow at 360×640 with 140 % text | `app_flow_test` |
| Content package: 12 lessons, 101 items, 299 activities, 14 grammar notes, full Pre-A1→C2 map | `content_test`, `tool/validate_content.dart` |
| Content validator (17 rule families), each proven on a broken fixture | `content_test` |
| Lesson engine: teach/note steps + 11 exercise types, deterministic generation | `exercise_builder_test`, `app_flow_test` (full lesson driven through the UI) |
| Answer grading: correct / correct-with-accent-reminder / incorrect; ñ distinct | `answer_evaluator_test`, `app_flow_test` |
| Wrong answers: detected, explained, retried once, excluded from first-try score | `app_flow_test` |
| Lesson completion, best score, prerequisite unlocking | `progress_test`, `app_flow_test` |
| FSRS-6 scheduling: learning steps, graduation, lapses, growth, retention setting, idempotent cards, atomic history, UTC instants | `fsrs_test` |
| Review UI: reveal-before-rate, four ratings with intervals, in-session learning steps, production cards with forced *Again* on a wrong answer | `app_flow_test` |
| Practice: listening, writing, pronunciation (self-assessed), error-focused | `exercise_builder_test`, `app_flow_test` (writing run) |
| Error notebook: one record per target, count, reopen, resolved after two correct answers | `progress_test`, `app_flow_test` |
| Daily plan for 20/45/60 min, deterministic, with reasons | `progress_test`, `app_flow_test` |
| Study time, streak, 14-day chart, skill evidence, FSRS stats | `progress_test`, `fsrs_test` |
| Personal dictionary with search, work filter and language connections; grammar reference | `app_flow_test` |
| Settings persisted in SQLite, tolerant of corrupt values | `progress_test`, `app_flow_test` |
| SQLite schema v2, migration v1→v2 on a real file | `persistence_test` |
| Progress survives closing and reopening the database | `persistence_test` |
| Backup export / restore / reject-invalid / reset | `persistence_test` |

Test run for this drop: **93 tests, all passing** (`flutter test`), analyzer
clean with `--fatal-infos`, formatter clean, content validator clean.

## Implemented but NOT verified on a device

These exist in code but could not be exercised in the build environment
(no Android SDK or device available there):

- **Android build.** Not built locally. Verified only by the CI job
  `Android debug APK` — check its result for the referenced commit.
- **Spanish audio (device TTS).** The call path is tested with a fake; real
  voice output, voice availability detection and the accent/speed settings
  need a phone.
- **Backup file dialogs** (`file_picker` save/open). Serialisation is tested;
  the system dialogs are not.
- **On-screen keyboard behaviour**, the accent-key row, back-gesture handling.
- **App icon / splash** are still the Flutter defaults.

## Not implemented (and not claimed)

- AI tutor, roleplay, AI writing feedback — the Tutor screen states this.
- Voice conversation, speech recognition, recording, shadowing playback,
  pronunciation assessment. Listen-and-repeat is self-practice and never scored.
- CEFR assessment engine (checkpoints, unit/level tests, estimates).
- Listening library (graded dialogues, transcript toggle, segment repeat,
  speed control beyond normal/slow).
- Notifications / reminders.
- Saved phrases, verb conjugation reference, stories.
- Interview coach, work missions, the rest of A1 and all of A2–C2 lessons.
- Cloud sync. AI usage budget controls (nothing to budget yet).
- Native-speaker review of content.

## Known issues and limitations

1. Content is AI-authored (`author_reviewed`); not yet checked by a native
   Spanish teacher.
2. `respond` exercises accept a fixed list of answers; a correct but unlisted
   phrasing is marked wrong. Acceptable at Pre-A1/A1; AI feedback is the
   Phase 2 fix.
3. The due-review badge refreshes on data change and navigation, not on a timer.
4. Repeating an already-completed lesson today also satisfies the daily lesson
   goal (it counts completions dated today, not only first completions).
5. Review queue is capped at 60 cards per session.
6. Curriculum entities are in JSON, not SQL tables (deliberate — DATABASE.md).

## Blocked

| Item | Blocked on |
|---|---|
| Local Android build / emulator run | Build sandbox cannot reach the Android SDK host; CI covers the build |
| Phase 2 AI features | Owner decision: provider, backend, budget |
| `native_reviewed` content | A human Spanish teacher |

## Next recommended milestone

Phase 1.x hardening: device verification pass, reminders, listening library,
unit checkpoints, remaining A1 units — see `ROADMAP.md`.
