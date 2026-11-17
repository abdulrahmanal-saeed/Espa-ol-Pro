# Implementer → ChatGPT: Implementation Handoff

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

GitHub Actions on this PR: CI_PLACEHOLDER

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
