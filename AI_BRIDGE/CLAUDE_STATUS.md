# Implementer → ChatGPT: Implementation Handoff

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-012
updated_at_utc: 2026-11-17T13:00:00Z
review_requested_for_sha: 011fecb
branch: feat/a1-u6-final
pull_request: PR_FINAL_PLACEHOLDER (stacked: #7 → #8 → #9 → #10 → this)
also_awaiting_review: #7 (PHASE1-009), #8 (PHASE1-010), #9 (PHASE1-011), #10 (A1-U4/U5, described here)
last_review_acknowledged: REVIEW-008
project_status: A1_CONTENT_COMPLETE_IN_REVIEW__PRS_7_TO_11_AWAITING_REVIEW__DEVICE_AND_NATIVE_REVIEW_PENDING

> This handoff covers the last two PRs of the A1 stack: #10 (A1-U4/U5,
> commit `09c2991`) and this one (`94ab106`, `977ed8a`, `011fecb`). Review
> order: #7, #8, #9, #10, then this.

## A1 is complete in content (not "accepted")

The A1 content is now complete: **23 lessons in 6 units**, 12 A1 dialogues,
6 unit checkpoints, the **A1 level assessment** and a **verb reference**.

It is **not** declared complete or accepted. That still requires your review,
device checks and a native Spanish reviewer. All content is
`author_reviewed`.

### #10: A1-U4 food and shopping, A1-U5 city and travel (content 1.3.0)

**Lessons 21–28:**

- café: querer; té ≠ te; para mí;
- restaurant: la cuenta;
- prices to 100: cash or card;
- an office order: necesito; la factura ≠ la cuenta;
- ¿Dónde está?: estar for location;
- directions: del / al;
- transport: ir a + place, en + vehicle;
- hotel check-in.

**Also:** 4 dialogues and the checkpoints `chk_a1_u4` and `chk_a1_u5`.

### This PR: A1-U6, the verb reference, and the A1 level assessment (content 1.4.0)

**A1-U6 at the workplace (lessons 29–32):**

- hay vs está;
- nosotros / ellos / ustedes forms;
- ir a + infinitive (near future) for tasks and emails;
- a work phone call: ¿De parte de quién?, no está, leaving a message.

It also has 2 dialogues and the checkpoint `chk_a1_u6`.

**Verb reference (`verbs.json`, new `Verb` model, Library → الأفعال):**

- 16 verbs, with all six persons, a note, examples and the lesson that
  teaches each.
- **Validator:** each regular verb's six forms must equal the -ar/-er/-ir
  rules (*hablámos* is rejected).
- **Hand-entered verbs:** irregular verbs, and *enviar* with its accent
  shift, are entered by hand.
- **vosotros:** shown, and explained as Spain-only.

**A1 level assessment `lvl_a1`:**

- 24 questions across all six units and five skills; no speaking;
  4 dialogue sentences.
- Locked until every A1 lesson is completed (`levelCompleted`).
- A tile at the end of A1 on the path.
- The result screen carries the same "not a CEFR certificate or DELE exam"
  note.

### Defects found and fixed in this PR

1. **The A1 level-test tile was hidden when A1 was finished.** When every
   lesson was done, the path fell back to expanding Pre-A1, which hid the
   newly opened tile. It now expands the last level with lessons. Found by
   the new widget test.
2. **One dialogue fell just below the difficulty bar.** The estimator rated
   `dlg_a1_oficina` 94.6 % coverage because *nuestra* and *somos* had not
   been taught. The sentence was rewritten.
3. **Two older tests did not allow for level assessments.** The rule "no
   CEFR mention in an intro" now allows the negative disclaimer. The rule
   "dialogue questions must come from the same unit" now applies the level
   scope to level assessments.

## Verification (local, at `011fecb`)

| Check | Result |
|---|---|
| format, analyze | clean |
| content validator | v1.4.0: 32 lessons (23 in A1), 263 items, 16 dialogues, 10 assessments (114 questions), 16 verbs — OK |
| `flutter test` | **318 passed** |
| `a1_units_test` | every lesson of A1-U2…U6 completed end to end in the app |
| `verbs_and_level_test` | the rule check, 4 validator negatives, the library widget with audio, level gating and the path tile |
| screenshots | new 23_verb_reference; library and progress shots regenerated for the fifth tab and the new counts |

GitHub Actions: CI_PLACEHOLDER

## Not verified — device checklist

1. Library → الأفعال: open *tener*, tap ▶ on each form.
2. With all A1 lessons completed, the A1 level test opens from the end of A1
   on the path. Before that it is locked with an explanation.
3. Lesson 32 (phone call): the respond prompt and the dialogue audio.

## Next

- **Stop and wait for your review of #7–#11 and the owner's merge decisions.**
- Then the owner chooses:
  - **A2 content** (Phase 3);
  - **Phase 2** (AI tutor), which is blocked on the owner's provider, budget
    and server decision;
  - **the REVIEW-007 P3 settings follow-up**.

I will not merge anything; merging is the owner's decision.

---

# Earlier handoff on this stack: PHASE1-011 (PR #9)


owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-011
updated_at_utc: 2026-11-17T11:00:00Z
review_requested_for_sha: 76eef9a
branch: feat/a1-u2-u3
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/9 (stacked on PR #8 → PR #7 → main)
also_awaiting_review: PR #7 (PHASE1-009, REVIEW-008 fixes), PR #8 (PHASE1-010, Phase 1.2C)
last_review_acknowledged: REVIEW-008
project_status: A1_U2_U3_READY_FOR_REVIEW__PR7_PR8_READY_FOR_REVIEW__DEVICE_ACCEPTANCE_PENDING_OWNER

> Review order: #7, then #8, then this PR. Commits in this PR: `ad24e73`
> (a fix) and `76eef9a` (content). Earlier handoffs on the stack follow below.

## This PR: A1-U2 and A1-U3 (content 1.2.0)

All content is original and `author_reviewed`. It still needs native Spanish
review. A1-U1 ids are unchanged.

### Lessons

| # | Lesson | Items | Focus |
|---|---|---|---|
| 13 | `a1_u2_l1` My family | 9 | tener (tengo/tienes/tiene); los padres = parents |
| 14 | `a1_u2_l2` Age and possessives | 8 | ¿Cuántos años tienes?; mi/mis, su/sus; casado |
| 15 | `a1_u2_l3` What is he/she like? | 8 | adjective agreement; simpático (false friend) |
| 16 | `a1_u2_l4` My work team | 8 | este/esta es…; experience, reliability |
| 17 | `a1_u3_l1` What time is it? | 8 | es la una / son las…; y media, menos cuarto |
| 18 | `a1_u3_l2` Days of the week | 9 | el lunes vs los lunes; hoy |
| 19 | `a1_u3_l3` My normal day | 8 | yo forms; como ≠ ¿cómo?; por la mañana |
| 20 | `a1_u3_l4` Making an appointment | 8 | ¿Le va bien…?; de acuerdo; lo siento |

**What every lesson has:**

- Arabic objectives and a work-relevance line.
- Teach steps, then guided practice (choice, fill, match, listening) and
  independent practice (typing, ordering, dictation, a respond prompt with
  audio).
- A short reading text and a self-practice speaking step (never scored).
- Its items become FSRS cards.
- A prerequisite: the previous lesson (U2-L1 requires U1-L3).

**Professional situations:**

- presenting your team to a client (L16);
- describing a colleague's experience (L16);
- scheduling and rescheduling a client meeting formally with usted (L20);
- working hours and days (L18–19).

### Grammar notes (8)

- U2: `g_tener`, `g_possessives`, `g_adjectives`, `g_este_esta`.
- U3: `g_time`, `g_days`, `g_present_regular`, `g_appointments`.

**Language links for Arabic speakers:**

- tener for age ("عندي ثلاثون سنة");
- tu/tú and mi/mí;
- como/¿cómo?;
- false friends: los padres, simpático, agenda;
- sábado and السبت.

### Dialogues and checkpoints

- **4 dialogues:** `dlg_a1_familia`, `dlg_a1_equipo`, `dlg_a1_rutina`,
  `dlg_a1_cita`.
- **2 checkpoints:** `chk_a1_u2` and `chk_a1_u3`.
  - 10 questions and 3 can-dos each.
  - Each plays one dialogue sentence and explains its grammar questions.

### The difficulty estimator caught a content issue

`dlg_a1_equipo` scored "challenging" (93 % coverage) right after its lessons,
because one sentence used *quién* and *del*, which had not been taught. The
sentence was rewritten with taught words rather than relaxing the rule.

### Defect fixed: `ad24e73`

The progress screen's level counter showed "9 / 4" for 4 of 9 lessons, the
same RTL issue fixed for checkpoints in 1.2B. It now uses `fraction()`.

## Verification

Local, at `76eef9a`:

| Check | Result |
|---|---|
| format, analyze | clean |
| content validator | v1.2.0: 20 lessons, 167 items, 10 dialogues, 6 checkpoints — OK |
| `flutter test` | **305 passed** (PR #8: 301) |
| new `a1_units_test` | every new lesson completed end to end in the app with full marks; structure, prerequisites, work items; checkpoints grade fully with correct answers |
| screenshots | 07 (progress, fraction fix) and 22 regenerated |

GitHub Actions run 44059168635 on `1142caf`: format, analyze, content, generated code, secrets — success, **305 tests passed**; Android debug APK — success.

## Not verified — device checklist

1. Path: A1 shows 11 lessons. U2-L1 opens after U1-L3.
2. Lesson 17: listening items for the times ("Son las ocho y media").
3. Lesson 20: the respond prompt plays "¿Le va bien el viernes a las nueve?".
4. Checkpoint A1-U3: question 4 plays "Llego a las ocho y media." from the
   dialogue.
5. The progress screen reads "0 / 11" for A1, left to right.

## Next

A1-U4 (food and shopping) and A1-U5 (city and travel). Then A1-U6 (work),
the verb conjugation reference and the A1 level assessment. I will not merge
anything; merging is the owner's decision.

---

# Earlier handoff on this stack: PHASE1-010 (PR #8)


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

GitHub Actions run 44054728074 on `9e02250`: format, analyze, content, generated code, secrets — success, **301 tests passed**; Android debug APK — success.

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

GitHub Actions run 44054760860 on `3d973f4`: success, **270 tests passed**, APK built.

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
