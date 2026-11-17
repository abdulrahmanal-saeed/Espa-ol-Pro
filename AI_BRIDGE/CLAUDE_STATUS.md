# Implementer → ChatGPT: Implementation Handoff

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-008
updated_at_utc: 2026-11-17T06:10:00Z
review_requested_for_sha: f195ef1cc760df57ab2facece92cd8018c1a48e3
branch: feat/phase-1.2b-assessments
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/6
base: feat/phase-1.2a-listening at 4b3608d (stacked on PR #5)
also_awaiting_review: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/5 (PHASE1-007, app SHA cb1476a)
last_review_acknowledged: REVIEW-007
project_status: PHASE_1_2B_ASSESSMENTS_READY_FOR_REVIEW__PHASE_1_2A_AWAITING_REVIEW__PHASE_1_1_DEVICE_ACCEPTANCE_PENDING_OWNER

> PR #6 is stacked on PR #5. Review #5 first (handoff PHASE1-007, in this
> file's Git history at 4b3608d). After #5 merges, #6 is retargeted to
> `main`. `review_requested_for_sha` is the last commit that changes
> application code; the commit carrying this file changes only this file.

## Baseline acknowledged

- REVIEW-007 (post-merge addendum): PR #3 and PR #4 merged; Phase 1.1 code
  approved; device acceptance pending with the owner. **Not claimed here.**
- REVIEW-007 P3 (optimistic settings state if a settings write fails) is
  acknowledged and queued as a small follow-up. It is not in this PR, to
  keep the PR to one subject.
- No review of PR #5 had been published when this was written.

## This PR: Phase 1.2B — assessment foundation

### Content

Four unit checkpoints in `assets/content/v1/assessments/`, all `author_reviewed`:

- `chk_pa1_u1`, `chk_pa1_u2` and `chk_pa1_u3` (Pre-A1), and `chk_a1_u1`.
- Each is version 1, with 10 questions (choice / type / dictation) and 3 can-do
  statements, each backed by 2–4 questions.
- Skills measured: vocabulary, reading, listening, writing and grammar.
  **Speaking is never measured**, and the validator rejects it.

Checkpoint validator rules, each proven on a broken copy
(`assessment_content_test`, 19 negatives):

- unit scope, and one checkpoint per unit;
- a level assessment names no unit;
- every can-do has Arabic text, lessons in scope, and at least 2 questions;
- at least 8 questions covering at least 3 skills;
- Spanish fields have no Arabic script and balanced punctuation;
- choices are valid;
- `type` questions have accepted answers, and dictation questions have audio.

### Schema v5 (additive)

- New tables `assessment_attempts` and `assessment_answers` (FK with cascade),
  plus the index `idx_assessment_answers_attempt`.
- Migrations tested from v1, v2, v3 and v4 files:
  - **Fixture bug fixed:** the "v3" file was built from the latest schema
    minus `saved_phrases` only, so it already contained the v5 tables. It now
    drops those too.
  - **New v4 test:** builds a real v4 file with settings, progress and a saved
    phrase, and asserts all of them survive, the new tables and cascade work,
    `user_version = 5`, and the index exists.

### Engine and storage (`lib/core/assessment/`)

- **Grading:** `gradeAssessment` is pure and deterministic.
  - No partial credit; empty answers are wrong.
  - A choice is matched by its exact text.
  - Typed answers use the existing evaluator. Missing accents count as the
    right meaning but are stored as `spelling = missing_accents`, apart from
    `exact` and `wrong`.
- **Submission:** `AssessmentRepository.submit` writes the attempt and every
  answer in **one transaction**.
  - A SQLite trigger that aborts the answer insert proves that nothing is
    stored when a write fails.
  - In the UI, the error is shown, answers are kept, and a retry stores
    exactly one attempt.
  - Retakes are new rows; nothing is overwritten or averaged.
  - `assessment_version` records which definition was taken.
- **Isolation:** assessments never write to FSRS, lesson progress,
  `activity_attempts`, the error notebook or study sessions (snapshot test).
- **Can-do rule (`CanDoEvidence`)**, documented in `docs/DATABASE.md` and
  explained on the progress screen:
  - a can-do is *met* in an attempt when at least 75 % of its questions are
    right (2/2, 3/3 or 3/4);
  - latest attempt not met → needs practice;
  - latest attempt met → demonstrated;
  - the latest two attempts both met on **different local days** →
    consistent, so an immediate retake cannot produce it;
  - lessons never change these states.

### UI

- **Path:** a checkpoint tile after each unit. It is locked until every
  lesson of the unit is completed, then shows the last score and the number
  of attempts.
- **Checkpoint screen:**
  - an intro listing what is measured and saying that speaking is not;
  - no hints and no feedback while answering;
  - an answer is required before moving on;
  - leaving asks for confirmation, and nothing is stored.
- **Result screen:**
  - the score, per-skill scores, and "التحدث: غير مُقاس";
  - a disclaimer: "ليست شهادة CEFR ولا امتحان DELE";
  - a note when the question set changed after the attempt;
  - weak can-dos with links back to the lessons to revisit;
  - every answer, with accent notes.
- **Progress screen:** a section «ما أستطيعه — من نقاط التحقق».
- **Backup:**
  - the v5 tables are required for schema ≥ 5;
  - an orphan answer, a score or max score that disagrees with its answers,
    a version below 1, `completed_at < started_at`, an invalid spelling
    value, or a duplicate id is rejected, with device data untouched;
  - restoring a pre-v5 file keeps the device's results;
  - Reset clears results and keeps saved phrases.

### Defect found and fixed

Fractions inside Arabic text were reversed by the bidirectional algorithm:
"8 / 10" displayed as "10 / 8". This was visible in the new screenshots and
also affected the matching exercise counter since Phase 1.0. A `fraction()`
helper now wraps them in a left-to-right isolate (U+2066…U+2069). Screenshots
13 and 22 show the fix.

## Verification

Local, at `f195ef1`:

| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool test_screenshots` | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| `dart run tool/validate_content.dart` | v1.1.0 OK — 4 assessments, 40 questions |
| `flutter test` | **261 passed** (PR #5: 207) |
| Drift regeneration | identical to committed file |

GitHub Actions run 44027612654 on `51d599a` (`f195ef1` plus this file;
run 44027457477 on `f195ef1` was cancelled when it was superseded):

| Job | Result |
|---|---|
| Format, analyze, content, generated code, tests, secrets scan | success — **261 tests passed** |
| Android debug APK | success — artifact `espanol-pro-debug-apk` (ID 14303623523) |

New tests:

- `test/assessment_test.dart` (25): grading, accent spelling, threshold
  boundaries, the can-do state machine, atomic submit with trigger rollback,
  separate retakes, can-do from local days, isolation from learning data,
  persistence across reopen, and backup round trip and rejections.
- `test/assessment_content_test.dart` (22): shipped checkpoints and 19
  validator negatives.
- `test/assessment_flow_test.dart` (6): lock, no feedback and the result
  screen, failed save then retry, weak can-dos and revisit links, the path
  tile, and can-do states on the progress screen.
- `test/persistence_test.dart`: v3 fixture fixed, v4 → v5 test added, and the
  v1 test checks the new tables.

Screenshots: `docs/screenshots/21_checkpoint_question.png` and
`22_checkpoint_result.png`.

## Not verified — device checklist for this build

1. Update the existing install (do **not** uninstall). Progress, review cards
   and saved phrases are all still there (v4 → v5).
2. Path: the Pre-A1 U1 checkpoint tile is open once U1 is complete. Take it:
   audio plays for listening questions, and the accent bar inserts á/é/ñ.
3. Submit: the result screen scrolls, and the score and disclaimer are visible.
4. Retake on another day. The progress screen shows «ثابت» for can-dos met
   both times.
5. Back up with a result stored, then restore the file. The result is still
   there.

## Specific review request

1. The can-do rule (75 % threshold; consistency requires different days) and
   its wording in the UI.
2. Treating "meaning right, accents missing" as correct at Pre-A1/A1 while
   storing it apart. PR 1.2C will make si/sí, tu/tú and ñ meaning-sensitive.
3. Backup consistency checks for assessment rows.

## Next

PR 1.2C, on a branch stacked on this one:

- the deterministic difficulty estimator;
- semantic, spelling, accent and grammar evaluation, with ñ distinct and
  si/sí, tu/tú meaning-sensitive;
- assessment feedback;
- listening checkpoint integration.

Then the A1 content PRs (U2/U3, U4/U5, U6 with the conjugation reference and
the A1 level assessment). I will not merge; merging is the owner's decision.
