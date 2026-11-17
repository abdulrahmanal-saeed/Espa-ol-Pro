# Implementer → ChatGPT: Implementation Handoff

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-010
updated_at_utc: 2026-11-17T08:00:00Z
review_requested_for_sha: afdb946
branch: feat/phase-1.2c-quality
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/8 (stacked on PR #7, base fix/review-008)
also_awaiting_review: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/7 (PHASE1-009, REVIEW-008 fixes)
last_review_acknowledged: REVIEW-008
project_status: PHASE_1_2C_READY_FOR_REVIEW__PR7_REVIEW_008_FIXES_READY_FOR_REVIEW__DEVICE_ACCEPTANCE_PENDING_OWNER

> Review PR #7 (REVIEW-008 fixes, handoff PHASE1-009 below in this file's
> history at `97f6e2e`) first. This PR is stacked on it and adds Phase 1.2C
> only. Commits: `695a6a2`, `387de49`, `1ccbbdf`, and the merge of the fix
> branch, `afdb946`.

## Phase 1.2C — what this PR adds

### 1. Answer diagnosis (`lib/core/learning/answer_evaluator.dart`)

`evaluateAnswer` keeps its API. It now also returns an `AnswerIssue` that is
derived only from the typed string and the closest accepted answer:

| Issue | Verdict | Example |
|---|---|---|
| `accents` | accepted, with a reminder | telefono → teléfono |
| `accentMeaning` | **wrong** | si/sí, tu/tú, el/él, mi/mí, te/té, se/sé, de/dé, mas/más, aun/aún, esta/está, papa/papá — in both directions |
| `enye` | **wrong** | manana → mañana; ñ is a letter |
| `wordOrder` | wrong | the same words in another order |
| `grammarForm` | wrong | one word differs only in an A1 inflection ending, a plural, or an article: habla/hablo, buenos/buenas, casa/casas, el/la, trabajo/trabajamos |
| `spelling` | wrong | a near miss: Levenshtein ≤ 1 for words of up to 5 letters, otherwise ≤ 2 |
| `meaning` | wrong | anything else |

**Interrogatives (qué, cómo, dónde …) stay lenient at Pre-A1/A1.** This is a
deliberate, documented choice: the ¿ ? marks already carry the meaning.

**Where the diagnosis is used:**

- Lessons and review show `explanationAr`.
- The error notebook files typed mistakes as spelling, grammar, word order or
  vocabulary from the diagnosis, instead of "spelling" for everything.
- Checkpoints store the outcome in `assessment_answers.spelling`. The values
  are listed in `docs/DATABASE.md`; the old `wrong` value stays valid.
  Backups accept the new values.

### 2. Difficulty estimator (`lib/core/learning/difficulty.dart`)

The band is deterministic and depends on three numbers, all shown to the
learner:

- **Coverage:** the share of running words already met in completed lessons
  (vocabulary, their examples, and grammar-note examples).
- **New grammar:** grammar used by the text but not yet taught.
- **Sentence length:** words per sentence.

Bands:

| Band | Rule |
|---|---|
| Too difficult | coverage < 80 %, or 2 or more new grammar points |
| Challenging | coverage < 95 %, or 1 new grammar point, or more than 10 words per sentence |
| Very easy | coverage ≥ 98 % and at most 6 words per sentence |
| Appropriate | everything else |

Speaker names, capitalised names inside a sentence, and numbers are not
counted as vocabulary.

**Defect found and fixed:** a capitalised word that started a *later*
sentence in the same string was treated as a name. Detection is now
sentence-aware.

**Where it is shown:** a badge on each unlocked dialogue in the library, and
the band with its reasons on the dialogue screen.

**Tests** (`difficulty_test`, 14):

- every boundary: 80/79, 95/94, 98/97, 6/7 and 10/11 words, 1 and 2 new
  grammar points;
- word extraction;
- every real dialogue is very easy or appropriate right after its lessons;
- with no lessons, A1 dialogues are too difficult;
- the result is deterministic.

### 3. Checkpoints play dialogue sentences, and explain mistakes

- **Dialogue sentences:** a question can name a `dialogue_turn`; its audio is
  then exactly that sentence. The validator checks that the turn exists, that
  its dialogue belongs to the checkpoint's unit (or level), and that the
  question measures listening. Each rule has a negative test.
  - Four listening questions now use dialogue sentences.
  - `chk_pa1_u2`, `chk_pa1_u3` and `chk_a1_u1` are therefore **version 2**,
    and the content is v1.1.1.
  - With the REVIEW-008 fix, such questions also stay locked until heard.
- **Explanations:** `explain_ar` is shown on the result screen after a wrong
  answer, never during the checkpoint. All 8 grammar questions have one.
- **Outcome labels:** the result screen labels every typed outcome.
- **Edited checkpoints:** a result taken at an earlier version shows a note
  (tested).

## Verification

Local, at `afdb946`:

| Check | Result |
|---|---|
| format, analyze | clean |
| content validator | v1.1.1 OK |
| `flutter test` | **301 passed** (PR #7: 270) |
| screenshots | regenerated; 19 shows the badges |

GitHub Actions on this PR: CI_PLACEHOLDER

## Not verified — device checklist

1. Type `si` where `sí` is expected in a lesson: marked wrong, with the
   explanation.
2. The listening library shows a badge on each open dialogue; the dialogue
   screen lists the reasons.
3. Pre-A1 U2 checkpoint: question 2 plays «Bien, gracias. Hasta mañana.» from
   the dialogue.

## Specific review request

1. Is the meaning-accent list right for A1, and is keeping interrogatives
   lenient acceptable?
2. Are the inflection-ending heuristic's false positives acceptable? A
   different word with the same stem and an inflection-like ending is
   labelled a form error. It is wrong either way; only the label differs.
3. The coverage thresholds (95 % / 98 %).

## Next

A1 content PRs: U2/U3, then U4/U5, then U6 with the verb conjugation
reference and the A1 level assessment. I will not merge anything; merging is
the owner's decision.

---

# Previous handoff on this stack: PHASE1-009 (PR #7)

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
