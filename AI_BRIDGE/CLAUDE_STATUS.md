# Implementer → ChatGPT: Implementation Handoff

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-013
updated_at_utc: 2026-11-17T14:00:00Z
review_requested_for_sha: 9f86876
branch: fix/review-008
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/7
last_review_acknowledged: REVIEW-010
project_status: REVIEW_009_P2_P3_FIXED_ON_PR7__STACK_8_TO_11_REBASED_BY_MERGE__AWAITING_REVIEW

## REVIEW-009 / REVIEW-010: both findings fixed on PR #7

New application commits on `fix/review-008`: `9ddc13a` (P2) and `9f86876`
(P3). The stack #8 → #9 → #10 → #11 has each branch merged forward with
these fixes, with no force-push. Each branch's own handoff is unchanged
apart from that merge.

### P2: guided dialogue questions after a mid-session playback failure (`9ddc13a`)

The evidence now depends on audio that was **actually delivered**, not on a
voice that was available when the screen opened.

**How it works:**

- **Delivery log.** A new `SpeechDeliveryLog` (`lib/core/speech/delivery_log.dart`)
  records each sentence that `SpeakButton.play` really spoke: the engine
  still reports available after `speak`, and `DeviceTtsSpeech` marks itself
  unavailable when `speak` throws.
- **Recording answers.** `DialogueQuestionsScreen` takes a log mark in
  `initState`. In `onAttempt`, an answer to an audio question is recorded with
  `measured: false` unless that question's sentence was delivered after the
  mark.
- **What "unmeasured" means here:**
  - `DialogueProgress` counts only measured first attempts, so unheard
    answers do not advance the dialogue;
  - unmeasured attempts never create error-notebook records;
  - the result screen says how many answers did not count.
- **`recordAttempt(…, measured:)`** can only **downgrade** an attempt. It
  cannot make self-assessed practice measured.

**Tests:**

- `listening_flow_test`: a voice that reports available and then fails on
  the first sentence. Even right answers are stored with `is_measured = 0`,
  the dialogue's answered count excludes them, and the notice is shown.
- `progress_test`: a downgraded wrong answer creates no error record, and
  `measured: true` cannot upgrade a speak exercise.
- The existing no-voice tests (start gate, direct route) still pass.

### P3: unique-index creation no longer swallows every error (`9f86876`)

`_ensureOneAnswerPerQuestion` first queries for duplicate
`(attempt_id, question_id)` rows:

- **Duplicates present** (legacy only): the index is skipped, the data is
  kept, and `AppDatabase.assessmentAnswersDegraded = true`.
- **No duplicates:** `CREATE UNIQUE INDEX` runs **without any catch**, so
  any other failure propagates.

**Tests (`persistence_test`):**

- A legacy duplicate database opens with both rows kept, the flag set and no
  index.
- An unrelated failure (another object already using the index name) makes
  the open throw instead of continuing silently.

## Verification (local, `fix/review-008` at `9f86876`)

| Check | Result |
|---|---|
| format, analyze, content | clean |
| Drift regeneration | identical |
| `flutter test` | **275 passed** (was 270; +5 regression tests) |

CI after the fixes, all on application code including `9ddc13a` and `9f86876`; every run passed both jobs (tests and Android debug APK):

| PR | Head | Run | Tests |
|---|---|---|---|
| #7 | `34f966b` | 44069648158 | **275 passed** |
| #8 | `b9961dc` | 44069818348 | success |
| #9 | `84fe49a` | 44069828802 | success |
| #10 | `a4b018e` | 44069830535 | success |
| #11 | `763fe88` | 44069835150 | success (323 locally) |

## Stack after the merge-forward

| PR | Branch | Adds |
|---|---|---|
| #7 | fix/review-008 | 1.2B + REVIEW-008/009 fixes |
| #8 | feat/phase-1.2c-quality | 1.2C |
| #9 | feat/a1-u2-u3 | A1-U2/U3 |
| #10 | feat/a1-u4-u5 | A1-U4/U5 |
| #11 | feat/a1-u6-final | A1-U6, verbs, A1 level assessment |

Still pending:

- independent review;
- owner merge decisions, in order;
- device checks;
- native Spanish review.

I will not merge anything.

---

# Earlier handoff on this branch: PHASE1-009


owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-009
updated_at_utc: 2026-11-17T07:30:00Z
review_requested_for_sha: 1913f04 (code state: 1.2B + REVIEW-008 fixes, merged with main 9dd9764/b889e16)
last_application_commit: 3cd15ed
branch: fix/review-008
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/7
base: main
last_review_acknowledged: REVIEW-008
project_status: PHASE_1_2B_WITH_REVIEW_008_FIXES_READY_FOR_REVIEW__PHASE_1_2A_ON_MAIN_NEEDS_THIS_FIX__DEVICE_ACCEPTANCE_PENDING_OWNER

> **Why this PR exists.** PR #5 (1.2A) was merged into `main`, and PR #6 (1.2B)
> was merged into `feat/phase-1.2a-listening`, not into `main`, both before
> REVIEW-008's findings were fixed. This PR targets `main`. It brings in the
> reviewed 1.2B code (unchanged from `f195ef1`) plus the fixes for every
> REVIEW-008 finding, including the P2 that affects 1.2A code already on
> `main`. The diff against `main` is therefore "1.2B + fixes". The fixes
> alone are the three commits after `9d6afcd`: `7e55700`, `3cd15ed` and
> `e38a7b8`.

## REVIEW-008 — findings and fixes

### P2 — listening scored without audio (1.2A on main and 1.2B) → fixed in `7e55700`

**Checkpoints**

- **Start gate:** a checkpoint that contains any audio question cannot start
  unless a Spanish voice is available. A notice explains how to install one
  (`assessment-no-voice`).
- **Per-question lock:** a listening question cannot be answered until its
  audio has **actually played** in this attempt:
  - the options and the text field are disabled until then
    (`assessment-listen-first`);
  - `SpeakButton.play` now returns whether the sentence was spoken. A missing
    voice and an engine error both return `false`; `DeviceTtsSpeech` marks
    itself unavailable when playback throws;
  - so a voice that fails mid-checkpoint never unlocks the question, and no
    guess at an unheard sentence can reach `assessment_answers`.

**Dialogue comprehension questions (guided practice)**

- Without a voice they are neither offered nor recorded: the start button is
  disabled, and the questions route shows `questions-no-voice` even when
  opened directly.
- The dialogue screen detects the missing voice **before** anything is played
  (`spanishVoiceProvider`). It shows the notice and the transcript.
- The text-only reader is kept.

**Tests**

- `assessment_flow_test`:
  - no voice → the checkpoint cannot start and nothing is stored;
  - an option tapped before listening selects nothing;
  - an engine that fails while speaking keeps the question locked;
  - playing unlocks only that question.
- `listening_flow_test`: no voice → notice and text shown before playing;
  questions disabled; direct route refused; zero `listening` attempts stored.

**Known limit (documented):** a TTS failure *during* guided dialogue questions
is not detected per question. They are practice, not assessment, and they
cannot start without a voice. Checkpoints detect it per question.

### P2 — duplicate question answers accepted by restore → fixed in `3cd15ed`

**Restore** now rejects, before anything is deleted:

- duplicate `(attemptId, questionId)` pairs — this is the reviewer's exact
  reproducer, with a new row id and adjusted `maxScore`/`score`;
- attempts with no answers (`maxScore < 1`);
- answers with an empty question, can-do or skill.

**Database:** a unique index `idx_assessment_answers_question` on
`(attempt_id, question_id)`.

- It is created on **every open**, so installs already on v5 get it without a
  schema bump. Schema stays at **v5**.
- If an old database somehow held a duplicate, the index is skipped rather
  than deleting data or refusing to open. Neither the app nor restore can
  create one.

**Tests**

- `assessment_test`: the duplicate, empty-attempt and empty-field cases are
  rejected with device results unchanged; the database refuses a second
  answer to one question.
- `persistence_test`: the index exists after v4 → v5.

### P3 — consistency across question versions → fixed in `3cd15ed`

- `AttemptRecord` keeps `assessmentVersion`. "Consistent" now requires the
  previous pass to be **at the same version** as the latest.
- Needs practice and demonstrated still follow the latest attempt.
- The rule is documented in `docs/DATABASE.md` and its wording updated on the
  progress screen.
- Test: a v1 pass followed by a v2 pass is demonstrated; a second v2 pass on
  another day is consistent; a later failed v3 is needs practice.

## Verification

Local, on `fix/review-008` before the main merge (`e38a7b8`):

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| content validator | OK |
| `flutter test` | **270 passed** (PR #6: 261; +9 regression tests) |
| Drift regeneration | identical to committed file |
| screenshots | unchanged |

GitHub Actions run 44054760860 on `3d973f4`: format, analyze, content, generated code, secrets — success, **270 tests passed**; Android debug APK — success.

## Not verified — device checklist

1. With the Spanish TTS voice **removed**:
   - a checkpoint shows the notice and cannot start;
   - a dialogue shows its text and the notice;
   - its questions cannot be opened.
2. With the voice installed: in a checkpoint, the options stay disabled
   until ▶ is pressed, then work.
3. Update over the existing install (v4 or v5): progress, saved phrases and
   any checkpoint results are kept.

Phase 1.1 device acceptance remains with the owner and is not claimed here.

## Next (already implemented, will follow as a stacked PR)

Phase 1.2C is on `feat/phase-1.2c-quality` (CI-ready locally, 292 tests). It
will be rebased onto this branch and opened as a PR stacked on this one:

- answer diagnosis: meaning-bearing accents si/sí and tu/tú, ñ, word form,
  word order, spelling;
- the deterministic difficulty estimator;
- checkpoints that play dialogue sentences, and explanations for wrong
  answers.

I will not merge anything; merging is the owner's decision.
