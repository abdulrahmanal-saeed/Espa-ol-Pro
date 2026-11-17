# Implementation status

**Phase 1 — Working educational foundation.** PR #1 and PR #2 are merged
into `main` (PR #2 merge: `ef35c1e`). REVIEW-004 approved the Phase 1
engineering fixes (last reviewed application code: `65324da`). CI on the
merge passed with 105 tests and a debug APK
([run 43918437105](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43918437105)).

The owner confirmed five Android device checks with Codex (see below).
The remaining Phase 1 acceptance gate is a human review of the Spanish
content. Phase 1.1 work is in progress on later PRs.

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
| Lesson completion, best score, prerequisite unlocking and entry into A1 | `progress_test`, `app_flow_test` |
| FSRS-6 scheduling: learning steps, graduation, lapses, growth, retention setting, idempotent cards, atomic history, UTC instants | `fsrs_test` |
| Review UI: reveal-before-rate, four ratings with intervals, production cards with forced *Again* on a wrong answer | `app_flow_test` |
| Learning steps are never answerable before their due instant (waiting state with countdown) | `app_flow_test` (clock-controlled) |
| Every answer is persisted before the run advances; retries stored as attempt 2 and excluded from skill evidence | `app_flow_test`, `progress_test` |
| Failed writes keep the answer available for retry without grading it, scoring it, or advancing | `app_flow_test`, with SQLite failures on the first answer and the prompted retry |
| Practice: listening, writing, pronunciation (self-assessed), error-focused | `exercise_builder_test`, `app_flow_test` (writing run) |
| Error notebook: one record per target, count, reopen, resolved after two correct answers | `progress_test`, `app_flow_test` |
| Daily plan for 20/45/60 min, deterministic, with reasons | `progress_test`, `app_flow_test` |
| Study time, streak, 14-day chart, skill evidence, FSRS stats | `progress_test`, `fsrs_test` |
| Personal dictionary with search, work filter and language connections; grammar reference | `app_flow_test` |
| Settings persisted in SQLite, tolerant of corrupt values | `progress_test`, `app_flow_test` |
| SQLite schema v3, migrations v1→v3 and v2→v3 on real files | `persistence_test` |
| Progress survives closing and reopening the database | `persistence_test` |
| Backup export / restore / reset; v1–v3 restore compatibility and rejection of malformed fields with every existing row preserved | `persistence_test` |
| Review ratings, FSRS state, and active study time commit together and survive reopening SQLite | `persistence_test`, including failure during the study-time write |
| **Phase 1.1:** saved phrases («عباراتي»): save from vocabulary, examples, lesson notes and the grammar reference; search, audio, note, remove with undo; one record per sentence | `saved_phrases_test`, `app_flow_test` |
| **Phase 1.1:** schema v4 (`saved_phrases`), migration v3→v4 on a real file; backups include and validate it; pre-v4 restores and progress resets keep saved phrases | `persistence_test` |
| **Phase 1.1:** live due-review counter on Home and Practice: one timer to the next due instant, no polling, recomputed on resume | `due_counter_test`, `app_flow_test` (clock-controlled, no DB write) |
| **Phase 1.1:** time on an opened but unrated review card is stored when the app is backgrounded or the screen closes. All review study-time writes go through one serialised checkpoint, which advances only after a successful write and retries failed seconds; a flush during an in-flight rating cannot double count (REVIEW-004 P2, REVIEW-005 P2) | `study_time_checkpoint_test` (failure, retry, both race orders), `app_flow_test` (background, immediate exit) |
| **Phase 1.1 (part B):** daily local reminder with one inexact alarm. Launch, resume and Settings reconcile the latest saved preference through one queue. Settings reports the current Android permission, and a tap opens Home through a route allow-list. | `reminders_test` covers daylight saving, zone changes, overlapping scheduling and cancellation, and failure recovery. `app_flow_test` covers Settings and resume races. Native delivery and reboot recovery are pending. |
| **Phase 1.1:** app identity: adaptive icon with themed (monochrome) layer, density PNGs, Android 12+ and legacy splash, matching in-app loading screen | `branding_test` (resources and colours); not yet seen on a device |

Local Windows verification used Flutter 3.50.0. All 105 tests passed,
including the A1 unlock regression. Analysis passed with `--fatal-infos`,
formatting and content v1.0.2 passed validation, and Drift regeneration
produced an identical checked-in file. The database and backup schema
remain at v3.

## Phase 1.2A — listening library (PR in review)

| Area | Evidence |
|---|---|
| Six original dialogues (4 Pre-A1, 2 A1-U1), 29 turns, 31 comprehension questions; content v1.1.0 | `listening_content_test`, `tool/validate_content.dart` |
| Dialogue validation: ids, level/unit/lessons, vocabulary taught by the linked lessons, grammar, speakers, script and punctuation, question integrity; each rule proven on a broken copy | `listening_content_test` (15 negative cases) |
| Dialogue player: whole dialogue turn by turn, single-sentence replay, pause (stops; resume restarts the sentence), stop, three speeds, no-voice state; stale playback can never move the state | `dialogue_player_test` |
| Library: dialogues unlock when their lessons are completed; progress derived from first attempts | `listening_flow_test`, `listening_content_test` |
| Player screen: transcript and Arabic translation hidden by default with toggles; only Spanish reaches the voice; sentences saved to «عباراتي»; vocabulary and grammar links | `listening_flow_test` |
| Comprehension questions: audio played, sentence not shown; answers stored as attempts (context `listening`); retries are attempt 2 | `listening_flow_test` |
| Not verified on a device: real TTS sequencing of turns, pause/resume timing, speed changes, long dialogues | — |

## Phase 1.2B — assessment foundation (PR in review)

| Area | Evidence |
|---|---|
| Four unit checkpoints (Pre-A1 U1–U3, A1-U1), 10 questions each, 3 can-dos each, JSON definitions with versions | `assessment_content_test`, `tool/validate_content.dart` |
| Checkpoint validation; each rule proven on a broken copy | `assessment_content_test` (19 negative cases) |
| Schema v5 (`assessment_attempts`, `assessment_answers`), additive; v1/v2/v3/v4 → v5 with data kept | `persistence_test` |
| Deterministic grading; no partial credit; missing accents recorded as `missing_accents` | `assessment_test` |
| Atomic submission; a failed write stores nothing; retry stores exactly one attempt; results survive reopening; retakes are separate rows | `assessment_test`, `assessment_flow_test` |
| Assessments never change FSRS, lesson progress, attempts, errors or study time | `assessment_test`, `assessment_flow_test` |
| Checkpoint screen: locked until the unit is complete, no feedback while answering, exit confirmation | `assessment_flow_test` |
| Result screen: score, per-skill scores, "speaking not measured", no-certification disclaimer, accent notes, weak can-dos linking back to lessons | `assessment_flow_test`, screenshots 21–22 |
| Can-do states (not assessed / needs practice / demonstrated / consistent on two different days) with the rule shown in the UI | `assessment_test`, `assessment_flow_test` |
| Backup v5 round trip; v5 files missing the tables, orphan answers, score mismatches and invalid fields rejected with data untouched; pre-v5 backups keep device results; reset clears results, keeps phrases | `assessment_test` |
| Fractions ("8 / 10") read left to right inside Arabic text (also fixed in the matching exercise counter) | screenshots 13, 22 |
| Not verified on a device: checkpoint audio, keyboard with the accent bar, result screen scrolling | — |

## Android build and runtime

- The [code commit's CI run](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43900871431)
  passed verification and produced the debug APK. A Windows Gradle build
  could not resolve the Gradle repository.
- The CI artifact's checksum matched GitHub and the APK installed on an API
  36 Google Play emulator. Android system and System UI stopped responding
  during launch and relaunch. A clean AOSP emulator remained offline during
  the attempt.
- On a Samsung Galaxy A15 running Android 16, the APK opened and the learner
  completed the first lesson. The on-device database contained 11 correct
  graded attempts and 14 FSRS cards.
- **Owner-confirmed device checks (passed).** The owner tested these with
  Codex on a real Android device and reported all working, recorded in
  REVIEW-004: (1) reviews and progress after closing and reopening the app,
  (2) backup export and restore, (3) learning offline, (4) Spanish audio,
  (5) on-screen keyboard. This is owner testimony, not automated or
  reviewer-witnessed evidence.
- Not covered by that confirmation: every accent/voice/speed variant, every
  Settings/theme case, and the A1 transition on device. Automated tests
  cover some of these paths. See [device evidence](REVIEW_HANDOFF.md#4-android-device-checks).
- Phase 1.1 replaces the default icon and splash. Their appearance on a
  device has not been checked yet.

## Not implemented (and not claimed)

- AI tutor, roleplay, AI writing feedback — the Tutor screen states this.
- Voice conversation, speech recognition, recording, shadowing playback,
  pronunciation assessment. Listen-and-repeat is self-practice and never scored.
- CEFR level estimates and the A1 level assessment (unit checkpoints exist; they are practice evidence, not certification).
- Verb conjugation reference, stories.
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
   (Inside a review session, waiting cards are released by a one-second timer.)
4. Repeating an already-completed lesson today also satisfies the daily lesson
   goal (it counts completions dated today, not only first completions).
5. Review queue is capped at 60 cards per session.
6. Curriculum entities are in JSON, not SQL tables (deliberate — DATABASE.md).
7. Spelling quality is not yet reported separately: an answer accepted with
   an accent reminder is stored as correct. Planned for Phase 1.2 together
   with stricter accent requirements at higher levels.
8. A final flush started while the review screen is being closed is not
   awaited (dispose cannot wait). It is normally preceded by the lifecycle
   flush when the app leaves the foreground, which is the reliable path
   before Android kills a process.
9. Attempts recorded before schema v3 all count as first attempts, because
   the distinction was not stored then.
9. Review study time is checkpointed with completed ratings. Time spent on
   the last unrated card is lost if the learner exits or the app terminates.

## Blocked

| Item | Blocked on |
|---|---|
| Remaining physical Android checks | Device checklist in `REVIEW_HANDOFF.md` |
| Phase 2 AI features | Owner decision: provider, backend, budget |
| `native_reviewed` content | A human Spanish teacher |

## Next recommended milestone

Finish device verification and obtain independent sign-off. The next
curriculum and practice milestones are listed in [the roadmap](ROADMAP.md).
