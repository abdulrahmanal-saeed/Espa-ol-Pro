# Architecture

## 1. Requirements in one page

**Product.** A private Spanish academy for one Arabic-native learner with a
sales / client-relations / IT-services background. Goal: real communicative
ability, Pre-A1 → C2, with B2 as the first professional milestone.

**Hard constraints.** Single user · Android first · offline-first · Arabic RTL
UI with Spanish LTR content · no accounts, payments, ads, social features or
analytics · no secrets in the app · all progress recoverable from a backup ·
no fabricated scores or simulated features.

**Non-goals (deliberately absent).** Authentication, cloud sync, leaderboards,
teacher dashboards, push marketing, streak-driven mechanics.

## 2. Stack and dependency decisions

| Concern | Choice | Why | Licence |
|---|---|---|---|
| UI | Flutter 3.50 + `material_ui` (Material 3) | Single Android codebase, first-class RTL | BSD-3 |
| State | `flutter_riverpod` 3 | Compile-safe DI, trivial test overrides | MIT |
| Routing | `go_router` 18 | Shell routes for bottom navigation, deep links | BSD-3 |
| Database | `drift` 2 over `sqlite3` 3 | Typed SQL, migrations, reactive queries | MIT |
| Spaced repetition | `fsrs` 2.0.1 | Official Open Spaced Repetition port of FSRS-6 | MIT |
| Audio | `flutter_tts` 4 | Device TTS: offline, free, no data leaves the phone | MIT |
| Backup file I/O | `file_picker` 13 | System save/open dialogs, no storage permission | MIT |
| Fonts | IBM Plex Sans Arabic, Inter (bundled) | Offline, consistent Arabic + Latin typography | OFL 1.1 |
| Reminders | `flutter_local_notifications` 23, `timezone`, `flutter_timezone` | Local scheduled notifications with correct time-zone and reboot handling | BSD-3 / BSD-2 / Apache-2.0 |

Rejected for Phase 1: **Supabase / any backend** (nothing needs it yet),
**shared_preferences** (settings live in SQLite so one backup covers
everything), **share_plus** (the system save dialog is enough),
**cloud TTS** (cost + privacy, device TTS suffices), **audio recording
plugins** (no honest way to score pronunciation offline yet).

SQLite native library: `sqlite3` 3.x bundles SQLite through Dart build hooks;
`sqlite3_flutter_libs` is obsolete and not used.

## 3. Structure

```
lib/
  main.dart                 bootstrap: open DB → load settings + content → run app
  app/                      MaterialApp, theme (design tokens), GoRouter
  core/
    content/                content models, JSON parser, validator   (pure Dart)
    learning/               answer grading, exercise builder, progress, daily planner
    srs/                    FSRS persistence + invariants
    db/                     Drift schema + migrations
    backup/                 JSON export / restore
    speech/                 SpeechService abstraction + device TTS
    settings.dart           typed settings
    providers.dart          Riverpod wiring (the only DI container)
    widgets/                EsText, SpeakButton, AsyncView, EmptyState
  features/                 home · path · lesson · review · practice · library
                            · progress · settings · tutor (honest "not yet" screen)
assets/content/v1/          versioned curriculum package (JSON)
tool/validate_content.dart  content validation CLI (CI gate)
test/                       unit + widget tests
test_screenshots/           screenshot generator (evidence, not a CI gate)
```

Dependency direction: `features → core → (drift, fsrs)`. `core/content` and
`core/learning/answer_evaluator.dart` import no Flutter, so the same code runs
in the app, in tests and in the CLI.

### Key design decisions

1. **Curriculum is data, not code, and not in SQLite.** Lessons ship as a
   versioned, read-only JSON package; SQLite holds only what the learner
   produces, keyed by stable content IDs. A content update can therefore never
   destroy progress, and cards whose item disappears are skipped, not deleted.
2. **Exercises are generated deterministically** from authored activity specs
   (`ExerciseBuilder`), with distractors drawn only from already-seen items and
   seeded by a stable hash — reproducible in tests, no randomness at runtime.
3. **Grading is objective or absent.** Typed answers are normalised and
   compared; missing accents are accepted *with a reminder*; ñ is never
   treated as an accent. Listen-and-repeat is flagged `isMeasured = false` and
   excluded from every accuracy figure.
4. **First-try scoring + mastery loop.** A wrong exercise returns once at the
   end; only first attempts count, so retries cannot inflate the score.
5. **FSRS is delegated, not reimplemented.** `ReviewRepository` only persists
   state and enforces invariants (atomic rating + log, idempotent card
   creation, UTC instants). A wrong typed answer on a production card can only
   be rated *Again*. A card is offered only when `due <= now`: short learning
   steps wait behind a countdown instead of being answered early.
6. **The daily plan is a pure function** (`buildDailyPlan`): deterministic,
   explainable, every block carries its reason.
7. **No CEFR estimate is shown.** Progress shows evidence (attempts, accuracy,
   measured retention with a minimum sample) and says explicitly that this is
   not a level estimate until task-based assessments exist.

## 4. RTL / LTR

The app locale is `ar`, so every screen is right-to-left. Spanish is always
rendered through `EsText`, which forces `TextDirection.ltr`, the `es` locale
and the Latin typeface; Spanish word banks, text fields and chips are wrapped
in LTR `Directionality`. Directional icons use mirrored variants.

## 5. Offline behaviour

Everything in Phase 1 works without a network: content, exercises, FSRS,
progress, library, backup. Audio works offline when the device has a Spanish
TTS voice; when it does not, the app says so and every non-audio feature keeps
working. There is no online-only code path yet.

## 6. Security, privacy, cost

- No network permission in the release manifest; no backend; no analytics.
- Study reminders are local notifications scheduled on the device by
  `flutter_local_notifications`; nothing is sent to a server. Permissions
  added: `POST_NOTIFICATIONS` (asked only when the learner turns reminders
  on) and `RECEIVE_BOOT_COMPLETED` (to restore the reminder after a
  restart). No exact-alarm permission: the reminder is deliberately inexact.
- No secrets exist in Phase 1. `.env.example` documents the Phase 2 rule: the
  LLM key lives only in a backend proxy, never in the app or the repo.
- CI scans the tree for common key patterns.
- Learner data: one SQLite file in app-private storage; user-initiated JSON
  export through the system file dialog. No voice is recorded.
- Cost today: zero. Phase 2 must ship with a daily/monthly budget and a kill
  switch before any paid call is enabled.

## 7. Testing strategy

| Layer | What is proven | Where |
|---|---|---|
| Content | Shipped package passes every rule; each rule fires on a broken fixture | `test/content_test.dart`, `tool/validate_content.dart` |
| Grading | Accents, ñ, punctuation, alternatives, closest correction | `test/answer_evaluator_test.dart` |
| Exercises | Every lesson builds; options distinct; determinism; no synonym distractors | `test/exercise_builder_test.dart` |
| FSRS | Learning steps, graduation, lapses, retention setting, idempotency, atomic logs, time zones | `test/fsrs_test.dart` |
| Progress | Unlocking, best score, error notebook lifecycle, streak, planner, settings | `test/progress_test.dart` |
| Persistence | v1→v2 migration on a real file, restart survival, backup round-trip and rejection | `test/persistence_test.dart` |
| UI flows | RTL, navigation, full lesson, wrong answers, review session, practice, settings, small-screen large-text dark mode | `test/app_flow_test.dart` |

Widget tests drive the real app (real content, real in-memory SQLite, real
fonts) with only the clock and TTS replaced.

Not covered by automation: behaviour on a physical device (TTS voices, file
dialogs, keyboard), which needs a manual pass — see `REVIEW_HANDOFF.md`.
