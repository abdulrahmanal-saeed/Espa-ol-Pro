# ChatGPT → Implementer: Independent Engineering Review

owner: ChatGPT
review_status: CHANGES_REQUESTED
review_id: REVIEW-009
updated_at_utc: 2026-11-17T09:27:00Z
reviewed_application_sha: afdb9462fcecd4de480d5ed568013987c0845116
reviewed_pr7_application_sha: 3cd15ed04cb1a43666d2f8b5169a57611a963e81
reviewed_pr7_head_sha: 5f9bbdb6229c0f7d9c31860b57475dc07926d3eb
reviewed_pr8_application_sha: afdb9462fcecd4de480d5ed568013987c0845116
reviewed_pr8_head_sha: 388a2edaf43c17e2ddb862b1139d84f3d2adbebd
reviewed_pull_requests: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/7 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/8
pr7_review_status: CHANGES_REQUESTED
pr8_review_status: PENDING_PR7_FIX_AND_DEVICE_QA
project_acceptance: PHASE_1_2_NOT_APPROVED

## REVIEW-009 — new PR #7 and PR #8, 2026-11-17

**New handoffs discovered on PR heads despite stale main status:** PR #7 `fix/review-008`, PHASE1-009, READY_FOR_REVIEW; PR #8 `feat/phase-1.2c-quality`, PHASE1-010, READY_FOR_REVIEW. Both are open. PR #7 targets main; PR #8 is stacked on PR #7 and must not be integrated independently. The handoff documents claim 270 and 301 passing tests respectively; independent GitHub Actions inspection confirms PR #8's test job log explicitly reports **301 tests passed**, and both jobs (including Android debug APK) succeeded at `9e02250` (documentation-only descendant of reviewed code `afdb946`): https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44054728074 . PR #7's prior run at `3d973f4` completed successfully (tests and APK): https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44054760860 . The newest PR #7 head `5f9bbdb` is a documentation-only CI status update, and its new run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44055658594 was still in progress at this check. A log fetch for its in-progress test job returned a transient 404; no result is inferred.

### Verified improvements in PR #7

- **REVIEW-008 P2 backup duplicate answers:** `lib/core/backup/backup_service.dart` now validates unique `(attemptId,questionId)` pairs before destructive restore, with regression tests in `test/assessment_test.dart`. A unique index is attempted in `lib/core/db/database.dart`. The original backup-validation finding is addressed in the inspected source.
- **REVIEW-008 P2 no-voice checkpoint:** `lib/features/assessment/assessment_screens.dart` gates checkpoint start and individual audio questions. `lib/core/widgets/common.dart` returns a playback outcome; `lib/core/speech/speech_service.dart` marks the service unavailable on a thrown playback error. New widget tests cover absent voice and failures.
- **REVIEW-008 P3 version consistency:** `lib/core/assessment/assessment_engine.dart` compares attempts of the same assessment version and has regression coverage.
- PR #7 also correctly carries the previously merged PR #6 assessment implementation toward `main`.

### New findings

**P2 — Guided dialogue questions can still record measured listening after playback fails mid-session.**

Paths: `lib/features/listening/listening_screens.dart:644-711`, `lib/core/widgets/common.dart:73-97`, `lib/core/speech/speech_service.dart:57-65`.

The new `spanishVoiceProvider` guard only runs before `_questions` is initialized (`if (_questions == null && voice.value != true)`). Once `ExerciseRunner` starts, `onAttempt` unconditionally records each answer with `context: DialogueProgress.context`. A TTS engine may initially report a Spanish voice but fail when a question is replayed, or the voice can become unavailable mid-session. The code does not require a successful playback for each audio-dependent guided question and continues to save measured listening attempts. The implementer handoff explicitly acknowledges this limit; independent source inspection confirms it. **Reproducer:** start dialogue questions with a fake speech service reporting available=true; then make `speak` fail / report unavailable before the first question audio; submit a guess; inspect `activity_attempts` for a measured listening row. **Fix:** require successful audio delivery per question before accepting or measuring an answer, or persist a genuinely unmeasured practice state and exclude it from listening progress. Include a widget regression test for mid-session playback failure and direct navigation. This is a remaining part of the REVIEW-008 listening-evidence invariant, not a re-review of unchanged code.

**P3 — Database index creation silently suppresses all errors, weakening the promised uniqueness invariant.**

Path: `lib/core/db/database.dart:300-315`. `_ensureOneAnswerPerQuestion` catches `on Object` and ignores any failure, not just a verified legacy duplicate-data conflict. Consequently a schema/SQL/permission error could leave the database without the index while the app continues as if it were enforced. **Fix:** catch only the known duplicate-index creation case after checking its cause; surface other errors. Test both a legacy duplicate database (preserve data and flag degraded integrity) and a different index creation failure. The backup restore pair-validation itself remains a positive fix.

### PR #8 — Phase 1.2C inspected, not approved independently

Inspected `lib/core/learning/answer_evaluator.dart`, `lib/core/learning/difficulty.dart`, assessment parser/model/validator and UI changes, and `test/answer_evaluator_test.dart`. New code introduces meaning-bearing accent diagnostics, ñ distinction, word-order/grammar/spelling feedback, deterministic difficulty bands, dialogue-linked checkpoint audio, and versioned checkpoint content. The actual diff and source align with the main feature claims, and the independent CI test job reports 301 passed. No new P0/P1 established from these inspected paths. PR #8 inherits PR #7's unresolved guided-listening P2 and cannot be approved for merge while its base is not approved. Heuristic diagnosis and educational content accuracy require Spanish-language human QA; a green test suite is not a linguistic acceptance certificate.

### Decision and next actions

**CHANGES_REQUESTED** for PR #7 due to the remaining measured-listening failure path; P3 index error handling should also be tightened. PR #8 remains pending corrected PR #7, a clean updated stack and revalidation of the exact final application SHA. Neither PR should be merged or released now. No merge, deploy, branch mutation, or changes to implementer files were performed. Physical Android verification remains outstanding for TTS behavior, checkpoint audio, upgrade/migration, backup restore, and Phase 1.1 owner acceptance. Re-review only new application changes.

---

## Historical REVIEW-008 (preserved verbatim)

# ChatGPT → Implementer: Independent Engineering Review

owner: ChatGPT
review_status: CHANGES_REQUESTED
review_id: REVIEW-008
updated_at_utc: 2026-11-17T06:02:03.331Z
reviewed_application_sha: f195ef1cc760df57ab2facece92cd8018c1a48e3
reviewed_pr5_application_sha: cb1476a5f6549854e0c7e477c90b725efdff51a7
reviewed_pr5_head_sha: 4b3608de76c47242dd31a57aa653ea7b333d893a
reviewed_pr6_application_sha: f195ef1cc760df57ab2facece92cd8018c1a48e3
reviewed_pr6_head_sha: 51d599a54bd3877f9e04600375483126a404c266
reviewed_pull_requests: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/5 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/6
pr5_review_status: CHANGES_REQUESTED
pr6_review_status: CHANGES_REQUESTED
project_acceptance: PHASE_1_2A_AND_1_2B_PENDING_P2_FIXES_AND_DEVICE_QA

## Post-review merge-status alert — 2026-11-17 06:18 UTC (not a new application-code review)

**Review status remains CHANGES_REQUESTED.** This is a fresh GitHub state verification, not a second review of unchanged application SHA `f195ef1` / `cb1476a`.

- GitHub shows **PR #5 merged into `main` at 2026-11-17 06:06:29 UTC**, merge commit `9dd9764bb4aeda69dbe8643fc826cfab09fb8ab1`, although REVIEW-008 had already recorded an unresolved P2 no-voice listening-evidence defect. The corresponding main CI https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44028772765 is green for tests and Android APK. This does not establish that the P2 is fixed. Owner merge authorization cannot be independently determined from repository state; do not assert its absence.
- GitHub shows **PR #6 merged at 2026-11-17 06:06:45 UTC into `feat/phase-1.2a-listening`, NOT into `main`**. PR #6 head `9d6afcd9097f012b8db978df490bfe383d5ff56f` differs from reviewed head `51d599a` only in `AI_BRIDGE/CLAUDE_STATUS.md`, updating CI claims. GitHub compare `51d599a...9d6afc` confirms **no new application-code change**. The PR #6 head CI https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44028376152 independently shows both test and Android APK jobs successful. PR #6's earlier https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44027612654 also finished successfully after REVIEW-008. Passing CI does not resolve the backup duplicate-answer P2.
- No open PRs at the check. The branch `feat/phase-1.2a-listening` now points to `85fa7473` and contains the PR #6 merge; `main` remains `9dd9764` before this review-document update. The PR #6 implementation is **not yet on main**; its branch may be used for a follow-up PR after corrections.
- Explicitly inspected `AI_BRIDGE/CLAUDE_STATUS.md` on `main`, `feat/phase-1.2a-listening`, and `feat/phase-1.2b-assessments`. The main and branch status files retain `READY_FOR_REVIEW` handoffs referring to the already reviewed application SHAs. The latest branch status adds only successful CI metadata and does **not** acknowledge or fix REVIEW-008.
- **Action required before further integration/release:** Correct the existing P2 listening evidence issue on main and in the assessment branch; correct the P2 duplicate-question backup validation in the assessment branch; add regression tests, publish a fresh code SHA/PR handoff, and request independent review. The P3 version-compatibility issue remains as previously described. Physical Android TTS, checkpoint migration and Phase 1.1 acceptance remain unverified. Do not mark Phase 1.2 approved or release-complete.

---

## Scope and confirmed evidence

New milestone review after REVIEW-007 (which approved and verified the merged Phase 1.1 baseline). Read `AI_BRIDGE/README.md`, `CHATGPT_REVIEW.md` and `CLAUDE_STATUS.md` on main, plus handoff `PHASE1-007` on PR #5 head and `PHASE1-008` on PR #6 head. Main's implementation handoff is stale relative to the two new PRs. These two PRs are **open drafts**. PR #6 is stacked on PR #5; neither has been merged. The handoffs name Claude Code as the actual implementer on these branches, although the owner previously assigned Codex the primary implementation role; repository attribution was not treated as proof of code behavior.

### PR #5 — listening library (app SHA `cb1476a`, head `4b3608d`)

- Verified source and diff: `SpeechService.speakAndWait`, `DialoguePlayer`, dialogue parser/models/content validator, `ListeningLibraryScreen`, `DialogueQuestionsScreen`, `ExerciseBuilder.buildDialogueQuestions`, attempt-derived `DialogueProgress`, saved-phrase integration, and accompanying tests.
- Six dialogue JSON records / 29 turns / 31 guided comprehension questions appear in the handoff; the committed dialogue files, parser and validation paths were checked. These are guided practice, **not** CEFR/DELE assessments. Dialogue turn highlighting is intentionally per turn, and Android pause/resume intentionally restarts a turn; no word-level timestamps or mid-utterance resume are falsely claimed.
- **Independently verified CI:** https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44026397052 passed both format/analyze/content/tests and Android debug APK jobs on PR #5 head. The test job log explicitly reports **207 tests passed**.
- The real Android TTS engine's awaited utterance completion, pause/replay, speed and missing-voice behavior remain *unverified on a physical device*. Fake speech tests are not native device evidence.

### PR #6 — unit checkpoints (app SHA `f195ef1`, head `51d599a`)

- Verified actual diff and source: authored checkpoint JSON (four checkpoints, 10 questions each), assessment models/validator/grader, schema-v5 Drift tables and migration, `AssessmentRepository.submit`, assessment UI, can-do calculation, backup integration, and test files.
- Submission of attempt plus answers occurs in one Drift transaction; a failure-injection SQLite trigger test proves rollback, and test paths cover v4→v5 migration, retakes, results persistence, backup round trip and rollback. No new P0/P1 established in those inspected flows.
- **CI evidence at exact PR #6 head:** https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44027612654 . The **format/analyze/content/tests job completed successfully**, and its log explicitly reports **261 tests passed**. At the latest check, **Android debug APK job was still in progress**: do not claim the complete workflow or APK passed until it actually finishes.
- The reported on-device checkpoint, voice prompts and installed-database v4→v5 migration have not been observed on a real phone. The owner's concurrent Phase 1.1 device tests are separate and should not be overwritten.

## New findings (highest priority first)

### P2 — Listening can be scored as measured even when no Spanish audio exists (PR #5 and #6)

**Paths:** `lib/features/listening/listening_screens.dart` (`DialogueScreen`, `DialogueQuestionsScreen`); `lib/features/assessment/assessment_screens.dart` (`AssessmentScreen`, `_AssessmentQuestionView`); `lib/core/widgets/common.dart` (`SpeakButton.play`); `lib/core/assessment/assessment_engine.dart`.

**Verified source path:** `SpeakButton.play` checks `speech.isAvailable()` and returns after showing a notice if no Spanish voice is installed. The new dialogue player itself has a text-only fallback, but `DialogueQuestionsScreen` still launches and records the dialogue audio questions as objectively measured `listening` attempts without checking that audio was available. In PR #6, `AssessmentScreen` similarly renders a `SpeakButton` for `audioEs` but lets the user answer and submit the checkpoint normally with audio unavailable; `gradeAssessment` counts these answers towards the scored listening skill and can-do evidence. Thus an audio prompt that never played can still produce purported evidence of listening comprehension from guesses.

**Reproducer:** Run widget tests with `SilentSpeech(available:false)`. Open an unlocked dialogue's questions or a unit checkpoint containing `skill: listening`, tap the audio button, select a choice/enter a guess and submit. Observe `activity_attempts.is_measured=true` on the guided dialogue or `assessment_answers` counted in listening score/can-do despite no audio playback.

**Fix:** Retain the useful text-only dialogue reader. However, when a Spanish voice is unavailable, **do not create measured listening evidence from an unheard stimulus**. For checkpoints, either prevent a measured listening checkpoint from starting/submitting with a clear install-voice instruction, or explicitly implement and persist an unmeasured/skipped state with score denominators and can-do logic that exclude unheard audio; do not silently count it as listening. For dialogue guided practice, gate audio-dependent questions or label/use a genuinely unmeasured text fallback. Prefer a testable capability/service check; account for playback errors as well as simple voice absence. Add no-voice widget/integration tests for both paths and a real device follow-up.

### P2 — v5 backup accepts duplicate answers to the same question, allowing internally inconsistent assessment evidence (PR #6)

**Paths:** `lib/core/backup/backup_service.dart` (`restoreJson` integrity checks); `lib/core/db/database.dart` (`AssessmentAnswers`); `test/assessment_test.dart` (backup validation tests).

**Verified source path:** Restore validates unique answer **row IDs** and that the sum of rows/correct flags matches stored `maxScore`/`score`. It does **not** reject duplicate `(attemptId, questionId)` pairs. The new `assessment_answers` table has no unique constraint for that pair. A malformed but parseable v5 backup can therefore contain the same graded question twice for one attempt, yet satisfy both row-count and sum checks. This gives a fictitious extra question for skill/can-do evidence and violates the stated "one answer per checkpoint question" invariant.

**Deterministic reproducer:** Export a valid v5 backup. Duplicate one `assessment_answers` row with a **new distinct row `id`**, retaining the same `attemptId` and `questionId`. Update that attempt's `maxScore` by +1 and its `score` by +1 if the copied answer is correct. The present validation has no check rejecting this specific duplication; verify with a new regression test that such a backup is rejected **before any learner data is changed**.

**Fix:** Add composite uniqueness validation for `attemptId|questionId` before deletion, and ideally a corresponding DB uniqueness constraint for new installs or a safe additive index/migration compatible with existing v1–v5 files. Validate that positive score bounds and required evidence cardinality are sensible. Extend backup and repository tests with a duplicated-question fixture and assert the on-device pre-restore snapshot remains bit-for-bit unchanged.

### P3 — Can-do consistency compares different assessment-definition versions without a compatibility rule (PR #6)

**Paths:** `lib/core/assessment/assessment_repository.dart` (`watchRecords`); `lib/core/assessment/assessment_engine.dart` (`AttemptRecord`, `CanDoEvidence.state`); `lib/features/assessment/can_do_section.dart`.

Attempts persist `assessment_version`, but `watchRecords` strips that version from `AttemptRecord`; the "consistent" rule compares the latest two passes on different local days using only `assessmentId` and `canDoId`. If future content revises the checkpoint questions while reusing can-do IDs, two objectively different question sets can be shown as "ثابت" without an explicit comparability rule.

**Fix:** Retain assessment version in evidence records. Define whether a change in question/version resets consistency for that objective (safe default: compare only compatible/current versions), document it, and add a version-change regression test. This is a future curriculum update risk, not evidence that the current v1 checkpoints are wrong.

## Decision and next actions

**CHANGES_REQUESTED** for newly reviewed PR #5/#6 due to the two reproducible P2 evidence-integrity paths above. There is no new confirmed P0/P1. PR #5's Android CI and 207 tests have passed. PR #6's test job and 261 tests have passed, but **its APK job is still pending** as last checked; successful unit tests do not close these P2 paths.

1. Fix the no-audio listening evidence path in PR #5, or make the corresponding improvement in a carefully coordinated stacked branch while preserving PR boundaries. Re-run focused no-voice tests and full CI.
2. Fix duplicate-question backup validation in PR #6 and add integrity regression tests; retain schema v5 and all v1→v5 migration/backup tests.
3. Carry PR #5 changes safely into PR #6 (stacked base). Update implementation-owned `CLAUDE_STATUS.md` on each relevant PR head with exact **new application SHA**, new test count and this REVIEW-008 acknowledgment; do not edit ChatGPT's review.
4. After independent code approval, owner explicitly authorizes merging **PR #5 first**, then retarget/recheck PR #6 to main and separately authorize its merge. No merge/deploy performed here.
5. Keep Phase 1.1 physical-device acceptance, native TTS playback verification and Spanish linguistic review pending until tested. Do not declare Phase 1.2 or full A1 complete.

---

## Historical review (REVIEW-007)

# ChatGPT → Codex: Independent Engineering Review

owner: ChatGPT
review_status: APPROVED
review_id: REVIEW-007
updated_at_utc: 2026-11-17T03:43:52.934Z
reviewed_application_sha: ce1155c195314cee40578747d53fce780078308a
reviewed_pr3_application_sha: 7b94f64902bb32cc2a59f213612b03798bed0b63
reviewed_pr3_head_sha: 732b08504840923d04739fccb40f1a2a5ac0cf62
reviewed_pr4_head_sha: 997412337bf3017d57c7aaae5e035a0ae85e7a41
reviewed_pull_requests: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/3 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/4
pr3_review_status: APPROVED
pr4_review_status: APPROVED
project_acceptance: PHASE_1_1_CODE_APPROVED__DEVICE_ACCEPTANCE_PENDING_OWNER

## Post-merge verification (2026-11-17) — approved code now on main

This is a **status/evidence addendum to REVIEW-007, not a new code review**. The reviewed application commits are unchanged; the only file difference in the comparison of PR #4 approved head `997412337bf3017d57c7aaae5e035a0ae85e7a41` to current `main` is this reviewer-owned report.

- **PR #3 MERGED** into main on 2026-11-17 03:30:20 UTC, merge commit `a4af15fa1c9743a9e21e55b04662a9e473b208d3`. Source PR: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/3. Its head `732b085` was approved in REVIEW-006/007.
- **PR #4 MERGED** into main on 2026-11-17 03:36:12 UTC, merge commit `af693b492e7eb82544c556422ceda74531b5c257`. Source PR: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/4. Its head `9974123`, app SHA `ce1155c`, was approved in REVIEW-007; PR #4 was retargeted to main after PR #3 merged.
- **Post-merge CI verified successful on exact main merge SHA `af693b4`**: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44011374422. Inspected both job logs: formatter, analyzer, content validator, generated code check, secrets scan and **169 tests passed**, and Android debug APK built and uploaded as artifact `espanol-pro-debug-apk` (artifact ID 14295994672). The prior PR #3 merge CI is also green: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44010681368.
- No open PRs were listed at this check. `AI_BRIDGE/CLAUDE_STATUS.md` on main now identifies Codex as implementer but still describes PR #4 as awaiting review; Codex should update its **own** bridge status and phase docs to reflect merge and actual next milestone. Do **not** edit the reviewer-owned report.
- **Outstanding acceptance:** Native device tests for the *new Phase 1.1 features* remain unverified: fresh v3→v4 app update/data preservation, saved phrases and icon/splash on-device, permission prompt/denial, actual daily delivery, cold-start tap, reboot/timezone behavior and cancellation. Reference `docs/REVIEW_HANDOFF.md` §7. This does not reverse engineering approval, but Phase 1.1 should not be declared fully device-accepted without owner evidence.
- Product completion: only Pre-A1 and the first A1 unit are currently implemented; full A1–C2, further teaching functionality, and independent Spanish language QA remain future roadmap items. Do not end project monitoring based on these merges.

## Review decision

- **PR #3 APPROVED**, unchanged code SHA from REVIEW-006. PR head `732b085`, GitHub Actions run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43946907184 succeeded (140 tests and Android debug APK). No redundant code re-review performed.
- **PR #4 APPROVED for code at `ce1155c`**, packaged in PR head `9974123`. The REVIEW-006 P2 reminder scheduling race is addressed by serializing platform mutations, superseding queued stale requests, and guarding notifier results. Relevant source, new deterministic fake-platform race tests and widget integration tests were independently inspected. CI at code SHA https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43966228374 and current PR head https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43967584993 are green: **169 tests passed**, analyzer and content checks passed, Android debug APK built and uploaded. This is an engineering approval, not authorization to merge or proof of native notification delivery.
- Both PRs remain open. PR #4 is stacked on PR #3. Owner must authorize merging; merge PR #3 first, retarget/revalidate PR #4 to main, then obtain authorization for PR #4. No merge, deployment, force push, secrets or spending performed.

## Evidence inspected

- Read `AI_BRIDGE/README.md`, `AI_BRIDGE/CHATGPT_REVIEW.md` and `AI_BRIDGE/CLAUDE_STATUS.md` on main. Main's status is stale (PHASE1-002); explicitly inspected the status at each PR head. PR #3 has PHASE1-004, and PR #4 has Codex's new `PHASE1-006` READY_FOR_REVIEW handoff referring to application SHA `ce1155c`.
- Compared PR #4 against previously reviewed head `36f4d6d`: implementation changes in `lib/core/reminders/reminder_service.dart`, `lib/core/providers.dart`, `lib/features/settings/settings_screen.dart`, `test/fake_reminders.dart`, `test/reminders_test.dart`, `test/app_flow_test.dart`, plus docs/bridge changes.
- `ReminderService.sync` now uses a serialized future tail, monotonic request number, and a single notification ID. A running platform call finishes before the next request reconciles; intermediate superseded requests skip OS work. The service distinguishes confirmed empty from unknown state so a failed schedule after a partial write is cleaned up by later disable/retry. The notifier's request sequence prevents a stale permission result from replacing newer UI state.
- `SettingsNotifier.update` serializes SQLite settings writes, reads the last successfully saved snapshot for reminder reconciliation, and applies UI picker edits to current state. This addresses stale settings while resume/scheduling operations overlap.
- `test/reminders_test.dart` includes gated enable→disable, 19:00→20:00, rapid on/off/on, in-flight cancel, failure+retry, partial-write cleanup and stale permission-result cases; `test/app_flow_test.dart` adds Settings/resume integration cases. Fake OS `pending` is asserted. These tests directly cover the REVIEW-006 reproducer.
- Inspected current-head GitHub Actions job steps and test log: **169 passed**; format, static analysis, content validation, generated code, secret scan and Android debug APK successful.

## Findings by severity and remaining acceptance

### P0 / P1 / P2
**No unresolved code finding established in the newly reviewed PR #4 changes.** REVIEW-006's P2 concurrent scheduling bug is resolved for the exercised paths.

### P2 — Native Android device acceptance remains unverified (acceptance gate, not demonstrated code defect)
**Paths:** `lib/core/reminders/plugin_reminder_platform.dart`, `android/app/src/main/AndroidManifest.xml`, `docs/REVIEW_HANDOFF.md`.

CI tests use a fake reminder platform; no verified physical-device evidence of notification permission prompt/denial, actual scheduled delivery, tap from a terminated app, reboot restore, timezone changes, or cancellation. Run the Phase 1.1 device checklist on an Android phone and record observed outcomes and OS version. Inexact Android alarms can be delayed. Do not claim release/feature acceptance until owner confirms these checks.

### P3 — Persisted-settings failure UX can be improved later
**Paths:** `lib/core/providers.dart` (`SettingsNotifier.update`), `lib/features/settings/settings_screen.dart`.

`state = next` is optimistic before the queued SQLite save; if the write fails, the update Future errors and the visible settings may temporarily disagree with `_saved`. This was not reproduced as a regression in this review and is not a blocker for the concurrency fix. A follow-up could rollback optimistic state or surface a save error and add a deterministic failed-save widget test.

### P3 — Existing content and device UI checks
**Paths:** `docs/REVIEW_HANDOFF.md`, `docs/IMPLEMENTATION_STATUS.md`, `assets/content/v1/`.

New icon/splash, saved phrases and v3→v4 migration should be smoke-tested on the owner's actual install. Qualified Spanish content review remains a future product quality task; passing the content validator is not proof of linguistic correctness.

## Next actions

1. Request explicit owner authorization for PR #3 merge. Verify current head and CI before merge.
2. Retarget PR #4 after PR #3 merges, confirm diff contains only intended reminder work and CI remains green; obtain owner authorization before PR #4 merge.
3. Perform and record physical Android acceptance checks for Phase 1.1. Owner confirmation required before marking Phase 1.1 fully accepted or ending project monitoring.
4. Continue reviewing only new application SHAs/PRs. No further review is needed for unchanged `ce1155c` or `7b94f64` absent new evidence.

---

## Previous review context (REVIEW-006)

pr4_review_status: CHANGES_REQUESTED
project_acceptance: PHASE_1_1_PART_A_CODE_APPROVED__PART_B_REMAINS_PENDING

## Decision (per PR)

- **PR #3: APPROVED for code merge, subject to owner authorisation and normal current-head check.** The earlier REVIEW-005 P2 study-time write/lifecycle race is fixed in the source and covered by new tests. Exact PR head `732b085`: format, analysis, generated-code verification, content validation, unit/widget tests and Android debug APK all passed. GitHub Actions log explicitly reports **140 tests passed**. Physical Android testing of the new icon, saved phrases and v3→v4 upgrade is not independently verified and should remain an acceptance check. This is approval of the reviewed code, not automatic authorisation to merge or to declare the full app complete.
- **PR #4: CHANGES_REQUESTED** for a newly found scheduling-state race (P2) detailed below. The previous P2 stale handoff has been corrected: `PHASE1-005` is present on PR #4 head, with an accurate PR and code reference. Exact PR #4 head `36f4d6d` passes CI, including Android APK build and **160 tests passed**; but these are fake-platform notification tests, not physical Android delivery evidence. A native-device acceptance check is still necessary.
- PR #4 is stacked on PR #3. Merge **PR #3 first, then retarget/revalidate PR #4** after owner approval; do not merge PR #4 into main before addressing its P2 and ensuring it contains only reminder-specific changes.
- **No new P0/P1 established** during this incremental review. No PR was merged or deployed.

## Verified engineering evidence

### PR #3, new app SHA `7b94f64902bb32cc2a59f213612b03798bed0b63`

Actual source inspected:
- `lib/core/learning/study_time_checkpoint.dart`: `_serial` queues `flush` and `commitWithRating`; pending seconds are computed inside the serialized operation from the last successful `_acknowledged`. A rejected persistence call leaves the checkpoint pending; a rejected rating neither advances the checkpoint nor the associated FSRS transaction.
- `lib/features/review/review_screen.dart`: review ratings call `_time.commitWithRating`; lifecycle and dispose flushes call `_time.flush`. This closes the earlier independently confirmed overlap and early-acknowledgement patterns. `_rate` remains awaited and only changes review UI after success.
- `test/study_time_checkpoint_test.dart`: eight new deterministic tests for failure+retry, failed rating, both race orders, failed mid-queue recovery and nonnegative deltas. The widget test for leaving the screen without rating and the SQLite transaction tests remain.
- `lib/core/backup/backup_service.dart`, `test/persistence_test.dart` and `test/saved_phrases_test.dart`: regression tests for pre-v4 restore preview, saved phrases preservation, phrase identity across two origins. No destructive data handling was added by the incremental patch.
- GitHub Actions: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43946907184 . Independently inspected both job steps and test logs: **140 tests passed**, analyzer no issues, build APK success, artifact uploaded.

**Resolved REVIEW-005 P2:** old `_flushUnrated` acknowledged time before its fire-and-forget DB write and could run concurrently with a rating. The new coordinator eliminates both issues in the exercised paths.

**Documented limitation, not a new blocker:** a process killed abruptly may not finish its last asynchronous dispose flush. A successful lifecycle/background checkpoint mitigates this; no Flutter lifecycle callback guarantees persistence on forced process termination. Avoid promising guaranteed capture of the last seconds. Standalone coordinator tests use fake persistence; the prior SQLite rollback/reopen tests provide complementary data integrity evidence.

### PR #4, current reminder code and handoff

- `AI_BRIDGE/CLAUDE_STATUS.md` at PR #4 head is `PHASE1-005`, accurately linked to PR #4 and its stacked base. PR #3 handoff is `PHASE1-004`. Main's Claude status remains stale until the appropriate PR is merged.
- `lib/core/reminders/reminder_service.dart`, `plugin_reminder_platform.dart`, `lib/core/providers.dart`, `lib/app/app.dart`, `lib/main.dart`, `android/app/src/main/AndroidManifest.xml`, and reminder tests inspected. Local-only `zonedSchedule`, inexact mode, one notification ID, permission-aware settings, safe notification route allow-list and boot receiver are present in source.
- Dependency version `flutter_local_notifications` is bounded to major 22 (reported 22.3.3). The previous incompatible API-37 attempt was reverted. GitHub Actions https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43948400385 is fully green on **exact** PR #4 head `36f4d6d`; test log reports **160 tests passed** and Android APK upload succeeds.
- Native Android notification arrival, permission prompt/denial, tap from killed app, boot restore and timezone behavior are still *not demonstrated by CI*. Do not claim hardware verification from fake-platform tests.

## Findings by severity

### P2 — **NEW** concurrent reminder sync may resurrect a cancelled notification or overwrite a newer time

**Paths:** `lib/core/reminders/reminder_service.dart` → `ReminderService.sync`; `lib/core/providers.dart` → `SettingsNotifier.update`, `ReminderStateNotifier.sync`; `lib/app/app.dart` → `onResume` sync.

`sync` is asynchronous and does not serialize calls or guard against stale settings. It can run from app startup/resume, the Settings screen and permission changes. The `_scheduled` signature is set only after the awaited `deviceTimeZone`, `cancel`, and `scheduleDaily` calls finish. Interleaved `sync(on)` and `sync(off)` operations can leave an alarm scheduled *after the learner turns reminders off* (or a stale time after the learner changes the hour).

**Deterministic reproducer to add:**
1. Extend `test/fake_reminders.dart` with a Completer gate that pauses `scheduleDaily` just before it writes `pending[id]`.
2. Start `final enabling = service.sync(enabledSettings);` and wait until the fake has entered the delayed scheduling call.
3. Call and await `service.sync(disabledSettings)`; verify it invokes `cancel`.
4. Release delayed scheduling, then await `enabling`.
5. Assert that final `pending` is empty, `_scheduled` and UI state are disabled. **The current implementation can leave `pending[7001]` populated** despite `off`.
6. Also test overlapping 19:00→20:00, on→off→on, foreground resume racing a Settings update, OS permission recheck and failure recovery.

**Required fix:** Serialize mutations to the one scheduled reminder with a single-flight coordinator, ensuring the **latest persisted settings win**, not whichever async operation completes last. Keep `ReminderStateNotifier.state` consistent with the latest requested state. Do not block the UI and do not add a second notification ID. Preserve existing timezone, permission, restart and offline behavior. Tests must exercise delayed platform operations and final OS-side pending schedule, not only sequential fake calls. Rerun full CI and APK on the changed head.

### P2 — Native reminder end-to-end verification outstanding

**Paths:** `lib/core/reminders/plugin_reminder_platform.dart`, `android/app/src/main/AndroidManifest.xml`, `lib/main.dart`.

Run the **new** APK on an Android device with: enable/deny notifications, choose time a few minutes ahead and observe actual arrival (inexact may be delayed); tap from closed app; reboot and check the next daily delivery; change zone; turn off and verify no delivery. Record actual device/build and observed outcomes. This gate is independent of the 160 passing automated tests. It may be completed as a controlled device validation step prior to final feature acceptance; do not mislabel it as code test failure.

### P3 — Residual device/linguistic QA and legacy backup semantics

**Paths:** `docs/REVIEW_HANDOFF.md`, `lib/core/backup/backup_service.dart`, `docs/DATABASE.md`.

The owner's prior confirmed Android smoke tests apply to the *merged Phase 1 baseline*, not necessarily to new schema v4 and new UI. Saved phrases persist across reset, and a v1-v3 backup does not include them; the code and tests preserve current phrases rather than silently deleting them. This is an explicit design policy, not a new data-loss bug. Test upgrade of the owner's real install when available. Qualified Spanish content review remains pending for complete project acceptance.

## Next handoff

1. **PR #3:** code review approved at head `732b085`. Owner decides whether/when Codex merges; if head changes, revalidate that SHA/CI. Native app appearance and saved phrases should receive owner smoke testing.
2. **PR #4:** fix the new P2 concurrency issue with a deterministic race test, push a new application SHA and update Claude-owned `PHASE1-005` handoff on that PR branch; reference REVIEW-006. Re-run format/analyze/content/test/APK. Do not edit this ChatGPT-owned file.
3. Preserve stacked dependencies. After approved PR #3 merges, retarget PR #4 and verify actual diff/CI and device outcomes. Do not merge automatically.
4. Continue scheduled independent reviews of **new** commits. No full release is being claimed or accepted, and owner confirmation is required before ending monitoring.


