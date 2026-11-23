# Implementer → ChatGPT: Implementation Handoff

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE4-004
updated_at_utc: 2026-11-23T13:00:00Z
review_requested_for_sha: a442f82 (B1-U2 application code and content; built on PR #19 head `c941190`)
branch: claude/hopeful-knuth-wbn3n3
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/19 (owner asked to add B1-U2 on top of #19)
last_review_acknowledged: REVIEW-019
project_status: B1_U2_READY__AFTER_PR19__DEVICE_AND_NATIVE_QA_PENDING

## Branch

The owner asked for the next B1 unit while PR #19 was open, and then asked
for B1-U2 to go **on top of #19**. This session can only push to
`claude/hopeful-knuth-wbn3n3`. So #19 now holds:

- strict accents and Spanish-first prompts (`c456fc8`), reviewed in
  REVIEW-019;
- the REVIEW-019 P3 fixes (`17acbc5`);
- B1-U2 (`a442f82` plus the docs commit).

Please review only the B1-U2 commits; the rest was already reviewed.

## B1-U2 «السرد والتجارب» (content 1.13.0)

| Lesson | Items | Focus |
|---|---|---|
| `b1_u2_l1` Antes y ahora | 8 | regular imperfect for habits: trabajaba, vivía, antes, siempre, normalmente, todos los días, a menudo, ya no |
| `b1_u2_l2` Cómo era | 8 | ser / ir / ver in the imperfect (era, éramos, iba, veía), había, estaba, tenía, de joven |
| `b1_u2_l3` Lo que pasó y cómo era | 8 | background vs event: mientras, de repente, en ese momento, sonó, me di cuenta de…, eran las…, hacía calor, llovía |
| `b1_u2_l4` Mi experiencia profesional | 8 | mi primer trabajo, el puesto, me encargaba de…, hace dos años, durante, al principio, con el tiempo, aprendí mucho |
| `b1_u2_l5` Un problema en el proyecto | 8 | resulta que, tuvimos que, conseguimos, el retraso, a tiempo, por suerte / por desgracia, la lección; hubo vs había |
| `b1_u2_l6` Lectura y escucha | 7 | **longer reading and listening** (owner decision): one ~150-word text with four questions, and the 12-turn `dlg_b1_historia` |

**Every lesson:**

- all ten activity types;
- `explain_ar` on every fill and grammar choice;
- a `work` item;
- prerequisites chain from `b1_u1_l5`;
- two FSRS cards per item, tested in the app for all six lessons.

**Distractors.**

- Every fill offers the target form, an infinitive and a participle, so the
  imperfect / indefinido choice is never forced between two forms that could
  both be right.
- The aspect contrast is tested only with unambiguous rules: the time and
  age in the past (eran / tenía, not fueron / tuve), de repente + an
  indefinido, and hace + a span + an indefinido.

**No grammar before its unit.** There is no subjunctive anywhere in the
unit; a test scans every Spanish string for it.

**Spanish-first prompts** (first content to use them):

- reading and listening choices in every lesson;
- two checkpoint questions;
- four dialogue questions.

The Arabic `prompt_ar` stays on all of them.

**Dialogues.** Four, all at 100 % known words right after their lessons:
`dlg_b1_antes`, `dlg_b1_manana`, `dlg_b1_entrevista`, and
`dlg_b1_historia` (12 turns, 6 questions). The estimator first flagged six
forms; they are now taught in item examples.

**Checkpoint `chk_b1_u2`:**

- 12 questions, 3 can-dos (4 questions each);
- the can-dos cover all six lessons;
- grammar 3, listening 3, writing 3, reading 2, vocabulary 1;
- 3 dialogue sentences;
- typed answers graded with strict accents.

**Verbs (61):**

- the imperfect for every verb: ser, ir and ver by hand, the rest
  machine-checked;
- new verbs: ver, sonar, encargar, conseguir, superar, mejorar.

**Engine.** The evaluator now recognises the imperfect endings. «Antes
trabajo en un banco» against «trabajaba» is diagnosed as a form mistake,
not as a different word.

## Verification (local, Flutter 3.50.0)

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| validator | OK — 68 lessons, 574 items, 1930 activities (1212 graded), 76 grammar notes, 38 dialogues (251 turns, 195 questions), 18 assessments (223 questions), 61 verbs |
| `flutter test` | **465 passed** (453 on #19 + 12 in `b1_u2_narration_test`) |
| screenshots | 07, 22 and 25 regenerated; new 26 (Spanish-first prompt on the long reading) |

Two B1-U1 assertions had pinned "only B1-U1 is available" and "no verb has
an imperfect". They now check what stays true: B1-U1 is first and
available, and no subjunctive yet.

## Questions for ChatGPT

1. The long reading has some forms not yet taught (propuso, sabíamos,
   querían, frecuentes). Following your REVIEW-019 guidance, the reading
   threshold is a soft authoring target. Is that density right for a
   lesson-6 reading?
2. Should the four reading questions repeat the full text on each screen, as
   now, or should we add a "read the text, then answer N questions"
   exercise type?

## Next step

1. After the owner merges #19: push B1-U2 as its own PR.
2. Then the longer reading and listening lesson for B1-U1.
3. Then B1-U3 (subjunctive), B1-U4, and `lvl_b1` with the B2 gate.

---

# Previous handoff (PHASE4-003, PR #19)

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE4-003
updated_at_utc: 2026-11-23T12:00:00Z
review_requested_for_sha: 17acbc5 (REVIEW-019 P3 fixes on top of c456fc8)
branch: claude/hopeful-knuth-wbn3n3
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/19 (base `main`, draft)
last_review_acknowledged: REVIEW-019 (and REVIEW-018)
project_status: B1_U1_MERGED__STRICT_ACCENTS_AND_SPANISH_PROMPTS_IN_REVIEW__DEVICE_AND_NATIVE_QA_PENDING

## Update: REVIEW-019 P3s fixed (`17acbc5`)

REVIEW-019 approved `c456fc8` with release gates, and noted two P3s. Both
are fixed in `17acbc5`; no other code changed.

1. **Arabic reveal carried over.** `BilingualPrompt` now resets its Arabic
   reveal in `didUpdateWidget` when its text changes. Regression widget
   test: reveal the Arabic, rebuild the same place with the next prompt,
   and the Arabic is hidden again.
2. **`prompt_es` on dictation.** The validator now rejects `prompt_es` on
   a dictation checkpoint question, whose screen shows a fixed
   instruction. Test on an edited copy.

Local: format and analyze clean, validator OK, **453 tests passed**
(451 + 2).

REVIEW-018 is acknowledged: it retrospectively approved PHASE4-002 /
`4933ca3`. Its note is kept: when a future gate (`lvl_b1` for B2) lands,
add restore tests for that assessment.

## Since PHASE4-002

- **PR #18 merged.** The owner explicitly approved the merge after
  exact-head CI was green on `58c9818`
  ([run 45156335009](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45156335009),
  440 tests, APK). Merge commit: `e901531`.
- **Not yet re-reviewed.** Your re-review of PHASE4-002 (the REVIEW-017 P2
  and P3 fixes, `4933ca3`) was not recorded before the merge. Please include
  it in this review. Any finding goes into a follow-up PR.

## Owner decisions (2026-11-23)

1. **Strict accents from B1.** Approved within REVIEW-017's boundaries.
   Built here.
2. **Spanish-first prompts.** Approved. The mechanism is built here; content
   starts using it in B1-U2, as REVIEW-017 recommended.
3. **B2 requires passing `lvl_b1`**, as B1 requires `lvl_a2`. Not built yet:
   the validator needs `lvl_b1` to exist. `requires_pass: "lvl_b1"` lands on
   B2 in the same PR as `lvl_b1`.
4. **Longer reading and listening in B1.** From B1-U2, every unit gets an
   extended reading text and a longer listening. B1-U1 gets them in a
   follow-up PR. The design is below, and I would like your view.

## 1. Strict accents (content flag `strict_accents`)

- **Content.** `strict_accents: true` on B1, B2, C1 and C2. The validator
  keeps the flag on for every later level once it starts.
- **Evaluator.** `evaluateAnswer(…, strictAccents)` now has a strict mode.
  In strict mode, an answer that differs only in written accents is
  incorrect. The issue stays `AnswerIssue.accents`, and the explanation
  becomes «من مستوى B1 تُحسب علامات النبر: الصحيح «…»». Exact answers, ñ
  and meaning-bearing accents behave as before at every level.
- **Where it applies** (from the level of the content):
  - lesson typing, typed fill, dictation and replies
    (`TypeExercise.strictAccents`, set by `ExerciseBuilder`);
  - practice runs (from the item's level);
  - dialogue dictation (from the dialogue's level);
  - checkpoints and level tests (`gradeAssessment(…, strictAccents)` from
    the assessment's level; the stored outcome is still `missing_accents`,
    now with `is_correct = false`, and the result screen says
    «علامات النبر ناقصة — تُحسب خطأ من مستوى B1»);
  - production review cards of B1+ items (a wrong typed answer can only be
    rated Again, as before).
- **Unchanged.** Receptive cards and multiple choice are not affected,
  since nothing is typed there. A1 and A2 grading is unchanged. Stored
  attempts are not regraded. There is no schema change.

## 2. Spanish-first prompts (content flag `spanish_prompts`)

- **Content.** `spanish_prompts: true` on B1 to C2.
- **Where `prompt_es` is allowed:** lesson `choice` and `respond`
  activities, checkpoint questions, and dialogue `choice` questions.
- **Validator.** It rejects `prompt_es` on a level without the flag, on any
  other type, with Arabic script, or with unbalanced ¿ ? / ¡ !.
  `prompt_ar` stays required.
- **Builder.** It passes `promptEs` on only when the level allows it, so A2
  stays Arabic even if such content slipped in.
- **UI.** `BilingualPrompt` shows the Spanish first, and «عرض بالعربية»
  toggles the Arabic. It is used by every exercise view and by checkpoint
  questions.
- **Generated exercises.** Their instructions ("اكتب بالإسبانية"…) stay
  Arabic in this PR: "selected comprehension instructions first", as you
  recommended. A Spanish table for them can follow in a later unit.
- **No shipped content uses `prompt_es` yet.** Tests use an edited B1-U1
  fixture. B1-U2 will be the first content to use it.

## 3. Proposed design: longer reading and listening (for your review)

- Each B1 unit gets a sixth lesson, «قراءة واستماع» (extended practice):
  - one reading text of about 120–180 words, with 4–5 comprehension
    questions;
  - one longer listening of about 10–12 turns, with 5–6 questions;
  - a short production task.
- It sits after lesson 5 and before the checkpoint, so the checkpoint opens
  after it.
- The difficulty estimator still applies: ≥ 95 % known words. The
  ≤ 10 words per sentence limit stays for listening. For reading I propose
  ≤ 14, a separate threshold.
- Alternative: no new lesson, just longer `choice` reading stimuli and a
  fourth dialogue per unit. The sixth lesson is cleaner for progress and
  FSRS, because it adds only a few items.

## Verification (local, Flutter 3.50.0)

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| validator | OK (content 1.12.0; counts unchanged from 1.11.0) |
| `flutter test` | **451 (440 + 11) passed** |
| CI | reported in the PR thread |

New test: `b1_accents_prompts_test` (11). It covers:

- the level flags;
- the evaluator in both modes, with ñ and meaning accents everywhere;
- builder strictness for B1 and A2 lessons, practice and dialogue
  dictation;
- checkpoint grading and labels, B1 against A2;
- the validator for the flags;
- `prompt_es` validation and builder behaviour;
- widget tests:
  - the lesson shows the Spanish prompt and toggles the Arabic;
  - a B1 lesson marks a missing accent wrong and stores it;
  - the same slip in A2 is accepted;
  - a B1 production review card without accents allows only Again.

One existing assertion changed: the content version (1.11.0 → 1.12.0).

## Questions for ChatGPT

1. Strict mode also rejects a missing accent on interrogatives (¿Cómo…?)
   from B1 on. Agreed?
2. The design for longer reading and listening (section 3): a sixth lesson
   or longer stimuli? Is a separate reading threshold of ≤ 14 words per
   sentence right?

## Next step

After review and the owner's merge:

1. the extended reading and listening for B1-U1;
2. B1-U2 (indefinido vs imperfecto, the first `prompt_es` content);
3. B1-U3;
4. B1-U4;
5. `lvl_b1`, with the B2 gate.

I will not merge without the owner.

---

# Previous handoff (PHASE4-002, merged in PR #18 → `e901531`)

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE4-002
updated_at_utc: 2026-11-23T11:00:00Z
review_requested_for_sha: 4933ca3 (application code; this handoff is the docs commit on top)
branch: claude/hopeful-knuth-wbn3n3
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/18 (base `main`, draft)
last_review_acknowledged: REVIEW-017
project_status: B1_GATE_AND_B1_U1_IN_REVIEW__REVIEW_017_P2_FIXED__DEVICE_AND_NATIVE_QA_PENDING

## REVIEW-017 acknowledged

The previous code SHA was `6742a96`. Its head `5fa9f80` had green CI:
[run 45154086857](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45154086857),
431 tests, APK artifact. REVIEW-017 found one P2 and one P3. Both are fixed
in `4933ca3`. No other code changed.

### P2: a partial attempt could open B1 (fixed)

I reproduced it first. An `AttemptRecord` for `lvl_a2` with one correct
answer made `CanDoEvidence.passed` return true, and B1 opened.

**The fix: completeness before a pass.**

- `Assessment.questionSet(version)` returns question id → can-do id, either
  for the current version or for a version listed in the new optional
  `retired_versions`. An unknown version returns null.
- `CanDoEvidence.isComplete(a, attempt)` requires:
  - the right assessment id;
  - a known version;
  - exactly that version's questions, once each;
  - the defined can-do on every answer.
- `CanDoEvidence.passedComplete` = `isComplete` && `passed`. Only this can
  open a level: in `passedAssessmentIds(pack, …)` / `LevelGates.from`, and in
  the result screen's "B1 opened" message.
- `passed` is unchanged for can-do states, since checkpoint evidence is
  unaffected.

**Older versions stay valid.**

- When `lvl_a2` changes, its old question set goes into `retired_versions`.
  A complete pass at that version still opens B1, so no legitimate learner
  is re-locked.
- `lvl_a2` is version 1 and unchanged since 1.10.0, so no retired list ships
  today.
- The validator rule: a retired version is ≥ 1 and below the current
  version, it is not empty, and its ids are not empty.

**Restore is checked before anything is deleted.**

- `BackupService` now receives the content from its provider. For an
  attempt at an assessment named by `requires_pass`, at a known version,
  the answer rows must match that version's question set. Otherwise the
  whole file is rejected (`BackupException`) before the transaction, and
  existing data is kept (tested).
- An unknown version is kept, because it may come from a newer app. It
  never opens a level.
- I limited this check to gating assessments, which have only ever had
  complete transactional attempts. Rejecting older unit-checkpoint data
  could lose real learner data if any checkpoint was ever edited without a
  version bump.
- No schema change.

### P3: -guar spelling (fixed in the rules)

- `regularSubjunctive('averiguar')` now gives averigüe / averigüemos.
- `regularPreterite('averiguar')` gives averigüé. The same gap existed in
  the past-tense rule, and it is fixed too.
- -gar is unchanged (pague).
- No shipped verb is affected.

## Regression tests added (`level_gate_test`, `verb_tenses_test`)

- The reviewer's repro: one correct answer: can-do rule true, completeness
  false, B1 locked.
- A full pass with all five can-dos opens B1.
- Only one complete can-do group: locked.
- A complete attempt missing one answer: locked.
- A duplicated answer row: locked. A relabelled can-do: locked.
- Everything answered but one can-do below 0.75: locked.
- An unknown version (0): locked.
- A complete pass at a retired version opens B1. The pack is edited so
  `lvl_a2` is at v2, with v1 retired, and the validator stays clean.
  A partial v1 attempt stays locked, and v1 answers labelled v2 stay locked.
- A failed retry after a pass stays open (existing test, unchanged).
- An edited backup is rejected before anything is deleted, and the device's
  existing answers are untouched. The edited backup keeps one answer, and
  `maxScore` and `score` are adjusted so the generic checks pass.
  Restored without content, it loads, but the gate still ignores it.
- The normal backup round trip keeps B1 open (existing test, now with the
  content).
- `retired_versions` validator: bounds, and empty sets.
- averigüe, averigüemos, averigüé, averiguó; pague unchanged.

Normal submission, SQLite uniqueness and FSRS behaviour are unchanged. The
existing assessment, persistence and gate-flow tests pass untouched.

## Verification (local, Flutter 3.50.0)

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| validator | OK (content 1.11.0, unchanged) |
| `flutter test` | **440 (431 + 9) passed** |
| CI | reported in the PR thread for the new head |

## Answers to REVIEW-017's policy notes

- **No overall minimum.** Agreed: with every can-do at 0.75 or more, the
  total is at least 0.75 too.
- **Strict accents and Spanish-first prompts.** Both stay proposals until the
  owner approves them. Your boundaries are noted: no regrading, ñ and meaning
  pairs everywhere, receptive cards not penalised, and Spanish-first from
  B1-U2 only on selected comprehension prompts.
- **«Yo en tu lugar» and «yo que tú».** Kept as they are: the first as the
  main form, the second as a note.
- **en cambio / por otro lado.** They share a group only to keep each other
  out of the distractors. They are not taught or graded as interchangeable.

## Questions for ChatGPT

1. Is limiting the restore check to gating assessments the right trade-off,
   or should every level assessment be checked?

## Next step

Re-review this head. After the owner merges #18: B1-U2 (indefinido vs
imperfecto). I will not merge.

---

# Previous handoff (PHASE4-001, reviewed in REVIEW-017)

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE4-001
updated_at_utc: 2026-11-23T22:00:00Z
review_requested_for_sha: 6742a96 (application code; this handoff is the docs commit on top)
branch: claude/hopeful-knuth-wbn3n3
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/18 (base `main`)
last_review_acknowledged: REVIEW-016 (with its CI follow-up)
project_status: A2_MERGED__B1_GATE_AND_B1_U1_IN_REVIEW__DEVICE_AND_NATIVE_QA_PENDING

## REVIEW-016 acknowledged; the A2 stack is merged

REVIEW-016 approved all four A2 PRs as `APPROVED_WITH_RELEASE_GATES`. The
owner then merged them in order:

| PR | Content | Merge commit |
|---|---|---|
| #14 | A2-U3 plans and the future (1.7.0) | `29b84e0` |
| #15 | A2-U4 preferences and comparison (1.8.0) | `3af8ef7` |
| #16 | A2-U5 simple work conversations (1.9.0) | `0abbdd6` |
| #17 | A2 level assessment `lvl_a2` (1.10.0) | `69c7d7d` |

I verified `main` at `69c7d7d` locally with Flutter 3.50.0 (archive
sha256 checked): format 0 changed, analyze clean, validator OK (57 lessons,
487 items, 31 dialogues, 16 assessments, 52 verbs), **394 tests passed**.

The release gates from REVIEW-016 stay open and are not mine to close:
physical-device QA and review by a native Spanish speaker. All content stays
`author_reviewed`.

REVIEW-016 P3 (accent policy, `finalStressNonVerbs`) and P3 (dialect notes)
are not changed silently here. The accent question is answered by the B1
proposal below.

## Owner decision recorded: B1 requires passing `lvl_a2`

- B1 lessons stay locked until the learner has **passed** the A2 level
  assessment.
- **Passed** = every can-do measured in the attempt is met at the existing
  threshold, `CanDoEvidence.threshold = 0.75`.
- Any passing attempt opens B1. A later failed retry does not re-lock it.
- A1 → A2 is unchanged: it does not require passing `lvl_a1`.
- This answers my PHASE3-007 question 1.

## PR scope (three commits)

1. **Engineering** `954cdc4`: the gate and the verb model.
2. **Content and tests** `6742a96`: B1-U1, content 1.11.0.
3. **Docs** (this handoff): README, CURRICULUM, CONTENT_SCHEMA,
   IMPLEMENTATION_STATUS, PROJECT_PLAN, screenshots.

### 1. The B1 gate

- `CanDoEvidence.passed(attempt)` (`assessment_engine.dart`): true when the
  attempt has answers and every can-do among them is `met`. The can-dos are
  read from the **stored answers**, so a pass keeps its verdict after the
  questions change. A pass at an older question version still counts.
- `LevelGates` (`lib/core/learning/level_gate.dart`) is computed from all
  stored attempts. **No new persisted state**: attempts and answers are
  already in SQLite and in backups (schema v5), so saved progress and backups
  are untouched. A restored backup restores the gate (tested).
- The rule is content: `"requires_pass": "lvl_a2"` on the `b1` level in
  `curriculum.json`. The validator requires an existing assessment, of kind
  `level`, belonging to an **earlier** level. A curriculum without the key
  still loads, with no gates.
- `ProgressRepository.isUnlocked` and `nextLesson` now take `gates` as a
  **required** argument, so no call site can forget it. `prerequisitesMet`
  keeps the old meaning. `gatedLesson` returns the lesson held back only by a
  gate.
- While attempts are still loading, a gated level reads as locked. The
  lesson intro of a gated level waits instead of flashing a lock.

**UI (Arabic):**

- Path: the B1 card shows "مقفل · يُفتح B1 بعد النجاح في «اختبار مستوى A2»",
  plus a card that explains the 75 % per-can-do rule and that one pass opens
  it for good. It has a button to the test. Tapping a locked B1 lesson shows
  the same reason in a snack bar with a «الاختبار» action.
- Lesson intro: the same card; «ابدأ الدرس» disabled.
- Home: the main button becomes «خُض «اختبار مستوى A2»», and the card is
  shown.
- `lvl_a2` intro: "النجاح في هذا الاختبار يفتح مستوى B1…".
- Result screen, one of three messages:
  - this attempt opened B1;
  - not passed, but B1 stays open after an earlier pass;
  - B1 still locked, revisit the suggested lessons.

### 2. Verb model: imperfect, conditional, present subjunctive

- `Verb.imperfect`, `conditional`, `subjunctive`, each optional, with
  `imperfect_regular`, `conditional_regular`, `subjunctive_regular` (default:
  `regular`, like `preterite_regular`).
- Rules: `regularImperfect` (-aba / -ía), `regularConditional` (infinitive +
  -ía), `regularSubjunctive` (swapped vowel, and -car → que, -gar → gue,
  -zar → ce, -ger/-gir → ja **in every person**).
- `Verb.optionalTenses` lists the past and the three new tenses. The
  validator applies the same checks to each tense: complete when given, no
  Arabic, no unknown person, regular forms equal to the rule. Messages keep
  the old wording for the past ("regular past form for…").
- Library → الأفعال shows each tense a verb has after the present and the
  past. The keys `verb-form-…` and `verb-past-…` are unchanged; the new ones
  are `verb-imperfect-…`, `verb-conditional-…`, `verb-subjunctive-…`.
- **A tense enters `verbs.json` only with the unit that teaches it.** B1-U1
  adds the conditional only. No verb has imperfect or subjunctive forms yet
  (tested).

### 3. B1-U1 "الرأي والتعليل" (content 1.11.0)

| Lesson | Items | Focus |
|---|---|---|
| `b1_u1_l1` Mi opinión y mis razones | 8 | pienso que, desde mi punto de vista, la opinión, porque / ¿por qué?, ya que, la razón, estoy seguro de que, me parece bien |
| `b1_u1_l2` Conectar las ideas | 8 | además, sin embargo, en cambio, por un lado / por otro lado, así que, por lo tanto, es decir |
| `b1_u1_l3` Lo que me gustaría | 8 | regular conditional: me gustaría, nos gustaría, preferiría, sería, estaría bien, debería, deberías, ¿Le importaría…? |
| `b1_u1_l4` Consejos y propuestas | 8 | irregular conditional: ¿Podría…?, podríamos, haría, tendríamos que, yo en tu lugar, sería mejor + infinitive, el consejo, la solución |
| `b1_u1_l5` Argumentar en una reunión | 8 | en primer / segundo lugar, por ejemplo, el argumento, a largo plazo, lo importante es…, en conclusión, convencer |

**Every lesson:**

- all ten activity types: listen_choose, listen_pick_es, type_es, order,
  dictation, fill, match, choice (reading and listening), respond, speak;
- `explain_ar` on every fill and grammar choice;
- at least one `work` item;
- prerequisites chain from `a2_u5_l5`;
- 2 FSRS cards per item (tested in the app for all five lessons).

**Distractors.**

- Fill distractors are an infinitive and a participle (escribir / escrito
  pattern), or forms that cannot complete the sentence (por qué / para after
  a clause, convenzo after tener que).
- Connector fills pair the answer with connectors of the opposite logic (a
  contrast against two consequences, and so on).
- Near-synonym groups (`syn`) keep defensible answers apart. Some existing
  items joined them: por eso, pero, quisiera, me encantaría, prefiero,
  puedes, ¿Me puede ayudar?, mejor, creo que, en mi opinión, estoy de
  acuerdo, de acuerdo, en resumen. A test proves the builder never offers a
  group member as a distractor for another.

**No grammar before its unit.**

- No structure that needs the subjunctive: no creo que, para que, cuando +
  verb, es importante que, me gustaría que, sería mejor que.
- No imperfect forms.
- The grammar notes say when those arrive (B1-U2, B1-U3).
- A test scans every Spanish string of the unit for them.

**Dialogues** (estimator: 100 % known words, about 7 words per turn, no new
grammar, all right after their lessons):

- `dlg_b1_horario` (lessons 58–59): two colleagues argue about working from
  home.
- `dlg_b1_cliente_enfadado` (lessons 60–61): advice on an angry client.
  Six forms were first unknown (enfadado, retraso, escribirle, proponer, ver,
  él); they are now taught in item examples.
- `dlg_b1_proveedor` (lesson 62): arguing for a supplier in a meeting.

**Checkpoint `chk_b1_u1`:**

- 12 questions, 3 can-dos (4 questions each);
- skills: grammar 3, listening 3, writing 3, reading 2, vocabulary 1; no
  speaking;
- 3 dialogue-turn questions;
- options shuffled per attempt;
- every grammar question has `explain_ar`.

**Verbs (55):**

- conditional added to ser, estar, preferir (irregular present, regular
  conditional, marked `conditional_regular: true`), tener, poder, querer,
  hacer (by hand), and hablar, llamar, necesitar, gustar (machine-checked);
- new: deber and importar (machine-checked) and convencer (yo convenzo, by
  hand).

**Accents.** No answer word ends in a stressed é/ó. The meaning pair
está/esta is still enforced, for example in the respond answer «… además,
está cerca».

## Verification (local, Flutter 3.50.0)

| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool test_screenshots` | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| `dart run tool/validate_content.dart` | OK — 62 lessons, 527 items, 1754 activities (1095 graded), 70 grammar notes, 34 dialogues (213 turns, 174 questions), 17 assessments (211 questions), 55 verbs |
| `flutter test` | **431 passed** (394 on `main` + 37 new) |
| `flutter test test_screenshots --update-goldens` | 07 and 22 regenerated; new 24 (locked B1 lesson) and 25 ("B1 opened" result) |
| CI | see the PR checks; result reported in the PR thread and the next handoff |

New tests:

- `level_gate_test` (13);
- `verb_tenses_test` (7);
- `b1_gate_flow_test` (4 widget tests): locked → pass on screen → unlocked;
  a failing attempt stays locked; a failed retry after a pass stays open;
  A1 → A2 needs no pass;
- `b1_u1_opinion_test` (13).

Existing tests changed only to pass the new required `gates` argument. One
coverage assertion now includes `b1` in the set of levels with dialogues.

No Android SDK in this container: the debug APK is built by GitHub Actions;
see CI above.

## Proposals for review before I build them (A2+ features)

### A. Stricter accent marking from B1

- Content flag `"strict_accents": true` on the B1–C2 levels, validated like
  `requires_pass`.
- `evaluateAnswer(input, accepted, {bool strictAccents = false})`. When
  strict, `AnswerIssue.accents` becomes **incorrect**, with an explanation
  ("من B1 تُحسب علامات النبر: …"). Meaning pairs (está / esta…) and ñ are
  already wrong at every level.
- Applies to:
  - typed answers in B1+ lessons (type_es, typed fill, respond, dictation);
  - B1+ checkpoints and level tests (stored as `missing_accents`, scored
    wrong);
  - B1+ dialogue dictation;
  - production FSRS cards of B1+ items.
- A1 / A2 stay lenient. Stored attempts keep their verdicts; nothing is
  regraded.
- Tests: the evaluator with both policies; a B1 lesson widget marks
  «deberias» wrong with the explanation; the same answer in an A2 lesson
  still passes; checkpoint grading.

### B. Gradually less Arabic in prompts

- An optional `prompt_es` on `choice` and `respond` activities and on
  checkpoint questions, allowed only at B1+ (validator: Spanish only,
  balanced ¿?).
- When present, the Spanish instruction is shown first, and a
  «عرض بالعربية» toggle reveals `prompt_ar`, which stays required.
- Generated exercises at B1+ get Spanish instructions from one table
  ("Elige el significado", "Escucha y escribe"…). One B1-U2 note teaches
  them.
- Steps:
  - B1-U2: reading and listening choice prompts;
  - B1-U3: respond prompts too;
  - `explain_ar` and grammar notes stay Arabic.
- Tests: a widget test shows the Spanish prompt and reveals the Arabic one;
  A2 is unchanged; the validator rejects `prompt_es` below B1.

I will build A and B in their own PR, only after review (or the owner's
go-ahead).

## Known issues

- The branch is the session-assigned `claude/hopeful-knuth-wbn3n3`, not
  `feat/b1-u1-opinion`. The environment only allows pushing to it.
- The gate is enforced where lessons are opened and chosen: path, lesson
  screen, `nextLesson`, home. `completeLesson` does not check it, just as it
  does not check prerequisites.
- While attempts load, a gated level reads as locked. The path can show the
  lock for a frame on a slow device.
- The 25-question `lvl_a2` is the whole gate. A learner who fails one can-do
  has to retake the whole test. That is by design, but it is worth watching
  on the device.
- Device QA (the gate on a phone, TTS for the new dialogues) and native
  review are pending.

## Questions for ChatGPT

1. Is "every can-do at ≥ 0.75" the right pass rule? Should there also be an
   overall minimum? (Today one can-do at 3/4 and the rest perfect is a pass.)
2. A pass at an older `lvl_a2` version still opens B1. Do you agree, given
   that a pass must never be taken away?
3. Proposals A and B: approve as designed, or change the scope? For example,
   should strict accents also apply to FSRS production cards?
4. Content: is «yo en tu lugar» right as the main form, with «yo que tú»
   only as a note? Are en cambio and por otro lado acceptable as one
   near-synonym group?

## Next step

After review and the owner's merge of this PR:

1. **B1-U2 "السرد والتجارب"**: indefinido vs **imperfecto**. Imperfect forms
   enter `verbs.json` with it.
2. Proposals A and B, as their own PR if approved.

I will not merge this PR; that is the owner's decision.

---

# Previous handoff (PHASE3-007, merged as PR #17 → `69c7d7d`)

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE3-007
updated_at_utc: 2026-11-23T17:00:00Z
review_requested_for_sha: f6246a9 (application code 54d4a2d)
branch: feat/a2-level-test
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/17 (stacked: #14 → #15 → #16 → #17)
also_awaiting_review: PHASE3-004 (#14), PHASE3-005 (#15), PHASE3-006 (#16)
last_review_acknowledged: REVIEW-015
project_status: A2_CONTENT_COMPLETE_IN_REVIEW__DEVICE_AND_NATIVE_QA_PENDING

## Review order

Review the stack in order: #14 (A2-U3), then #15 (A2-U4), then #16 (A2-U5),
then this PR (#17). Each PR adds only its own commits. With this PR, A2 has
all its content:

- 25 lessons in 5 units;
- 5 unit checkpoints;
- the level assessment.

None of it is "accepted" until it has been reviewed, checked on a device and
checked by a native speaker.

## Codex finding on #17: fixed

«Señor, ¿puedo firmar aquí?» is a valid request for permission, so `puedo`
was a wrong distractor in `lvl_a2.q1`.

- The prompt now states the intent: asking the gentleman to sign.
- The distractors are now poder and podido.
- The same fill in `a2_u1_l1`, already merged with #12, is fixed the same
  way.

## PR #17: A2 level assessment `lvl_a2` (content 1.10.0, `54d4a2d`)

**No app code changed.** The level-assessment logic built for `lvl_a1`
already works for any level:

- `levelAssessmentFor`;
- `levelCompleted`, which keeps the test locked until every lesson of the
  level is done;
- the tile at the end of the level on the path;
- `awaitsLevelTest`, which keeps the level expanded until the test has been
  taken.

**Questions:**

- 25 questions, in the `lvl_a1` format.
- 5 can-dos, one per A2 unit. Their lesson lists together cover every A2
  lesson. Each can-do has 4 to 5 questions.
- Skills: grammar 9, reading 5, listening 5, writing 4, vocabulary 2. No
  speaking.
- Dialogue sentences: one from each unit (`dlg_a2_averia.t5`,
  `dlg_a2_finde.t4`, `dlg_a2_cita_cliente.t5`, `dlg_a2_ofertas.t4`,
  `dlg_a2_seguimiento.t6`).
- Most items are new, not copies of the unit checkpoints. Two kinds repeat
  deliberately because they test core A2 contrasts: the register question
  (puede / puedes) and the formal email close.
- Every grammar question has `explain_ar`.
- Distractors are unambiguously wrong.
- The four typed answers are «la pantalla está rota», «llegué», «prefiero el
  negro» and «adjunto el archivo».
- The accepted answers deliberately leave out the unaccented forms. Both
  esta/está and llegue/llegué are meaning-accent pairs in the engine.

### Tests — `test/a2_level_test.dart` (5)

- Coverage of all A2 units and every A2 lesson.
- Five skills, no speaking, at least 4 questions per can-do, and 5 dialogue
  sentences.
- Grading of a missing meaning accent (llegue, esta) and of a wrong answer.
- The shuffle: the first displayed option is correct on fewer than half of
  the questions.
- Persistence across a database reopen.
- Widget:
  - locked with every A2 lesson but the last done;
  - after the last lesson, the tile shows on the path;
  - Start is enabled and the "not a CEFR certificate" note is shown.

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| content validator | OK: 16 assessments (199 questions) |
| `flutter test` | **394 passed** (389 + 5) |
| screenshots | 22 regenerated |

## Questions for ChatGPT

1. A1 → A2 progression does not require passing `lvl_a1`. Should A2 → B1
   follow the same policy? I have left it unchanged until the owner
   decides.
2. Is 25 questions enough for A2, or should listening carry more weight?

## Proposed next step

Once the stack is merged:

1. B1 unit 1, "Opinion and reasoning". It would follow the same model: 5
   lessons, 3 dialogues and a checkpoint.
2. Alongside it, the planned A2+ features: stricter accent marking and
   gradually less Arabic in prompts.

I will not merge #14–#17; that is the owner's decision.

---

# Previous handoff (PHASE3-006, still awaiting review)

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE3-006
updated_at_utc: 2026-11-23T16:00:00Z
review_requested_for_sha: latest #16 head (application code a3ec090 + the cuando fix)
branch: feat/a2-u5-work
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/16 (stacked: #14 → #15 → #16)
also_awaiting_review: PHASE3-004 (#14, A2-U3), PHASE3-005 (#15, A2-U4)
last_review_acknowledged: REVIEW-015
project_status: A2_U3_U4_U5_IN_REVIEW__ALL_A2_UNITS_HAVE_CONTENT__DEVICE_AND_NATIVE_QA_PENDING

## Stack and review order

1. #14 (A2-U3) — PHASE3-004
2. #15 (A2-U4) — PHASE3-005
3. #16 (A2-U5) — this handoff

Each PR targets the branch of the one before it and adds only its own
commits. Merge them in order; after each merge I retarget the next PR to
`main`.

## Codex finding on #16: fixed

A future event after `cuando` needs the subjunctive: «Te aviso cuando
esté listo». The subjunctive is not taught at A2, so I rephrased the four
places that had `cuando` with the indicative:

- the dialogue turn;
- a grammar example;
- a reading activity;
- a speaking activity.

They now use a time expression: «te aviso esta tarde», «te aviso en diez
minutos». No `cuando` + verb remains anywhere in the content.

## PR #16: A2-U5 "Simple work conversations" (content 1.9.0, `a3ec090`)

This PR completes the content of all five A2 units.

| Lesson | Content |
|---|---|
| `a2_u5_l1` Un correo formal | estimado, le escribo para…, el asunto, adjunto…, el archivo, la respuesta, quedo a la espera de su respuesta, un saludo, saludos cordiales |
| `a2_u5_l2` Mensajes rápidos | ¿Puedes…?, perdona, llego tarde, te aviso, sin problema, gracias por…, ya está, ahora voy, un abrazo; tú vs usted |
| `a2_u5_l3` Un cliente nuevo | me interesa…, el servicio, la información, el catálogo, ¿Me da su…?, el correo electrónico, ¿Cómo se escribe?, le paso con…, con mucho gusto |
| `a2_u5_l4` El seguimiento | como hablamos…, la semana pasada, la propuesta, ¿Pudo…?, le recuerdo que…, pendiente, quedamos en…, el próximo paso, cualquier duda |
| `a2_u5_l5` Cerrar la reunión | en resumen, acordamos…, el acuerdo, el contrato, entonces, por último, gracias por su tiempo, seguimos en contacto, hasta pronto |

**Activities.** Every lesson has the full set of activity types. Every
fill-in and grammar choice has an explanation for wrong answers.

**Distractors.** Each fill-in distractor is an infinitive or a participle,
so no distractor is also valid Spanish. This applies the Codex finding from
#14 and #15.

**Dialogues.** The estimator flagged two dialogues; both were rewritten and
all three now pass:

- `dlg_a2_mensajes`: no changes needed.
- `dlg_a2_cliente_nuevo`: the first version spelled a name letter by letter
  and used *mantenimiento*, which is not taught. The spelling turn was
  removed, and the word is now taught in an example.
- `dlg_a2_seguimiento`: *revisarla*, *firma* and *exacto* were not taught.
  They became *la revisé*, *para firmar* and *muy bien*.

**Checkpoint `chk_a2_u5`.**

- 12 questions covering 3 can-dos.
- Skills: reading 2, writing 3, grammar 3, listening 3, vocabulary 1.
- 3 questions play dialogue sentences.
- Options are shuffled.

**Verbs.** 7 new verbs, 52 in total:

- **dar:** doy; past di / dio, without an accent.
- **seguir:** sigo; past siguió.
- **recordar and acordar:** o→ue in the present; regular past.
- **adjuntar, avisar, interesar:** machine-checked.

### Verification

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| content validator | OK: 57 lessons, 487 items, 999 graded, 31 dialogues, 15 assessments, 52 verbs |
| `flutter test` | **389 passed** (379 + 9 in `a2_u5_work_test` + completing A2-U5 in `a2_units_test`) |
| screenshots | 07 and 22 regenerated |

## Questions for ChatGPT

1. Lesson 53 teaches "Estimado/a + name:" with a colon, which is standard
   in Spanish letters. Should we also mention "Hola, + name:" for
   semi-formal emails?
2. Should `lvl_a2` cover all five units with roughly 25 questions, like
   `lvl_a1`?

## Proposed next step

The **A2 level assessment `lvl_a2`**, built the same way as `lvl_a1`:

- it opens only when every A2 lesson is complete;
- it covers all five units and five skills, with no speaking;
- its tile appears at the end of A2 on the learning path.

I will not merge #14, #15 or #16. That is the owner's decision.

---

# Previous handoff (PHASE3-005, still awaiting review)

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE3-005
updated_at_utc: 2026-11-23T14:00:00Z
review_requested_for_sha: (see the latest PR #15 head; application code bb1f2e6, 4508d99 and the distractor fix)
branch: feat/a2-u4-preferences
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/15 (stacked on #14, base feat/a2-u3-future)
also_awaiting_review: PHASE3-004 / PR #14 (A2-U3)
last_review_acknowledged: REVIEW-015
project_status: A2_U3_AND_U4_IN_REVIEW__DEVICE_AND_NATIVE_QA_PENDING

## Stack

1. Review #14 (A2-U3, handoff PHASE3-004) first. Its head is `4b272b2`
   and CI is green: 368 tests, APK built.
2. This PR adds only the A2-U4 commits on top.
3. Merge #14 first, then retarget this PR to `main`.

## Codex findings on PR #15: fixed

**`4508d99`:** "¿Qué prefieres?" is valid Spanish, so `Qué` is no longer a
distractor. It is now an accepted alternative.

**Same pattern across A2-U4:** I checked every fill-in for distractors that
are also valid Spanish and fixed two:

- "Cree que…" is now pinned with "Yo ___".
- "porque es más cara" was replaced by the distractors para / de.

**A2-U3 (#14) got the same check** in `941c18b`. This branch includes it.

## PR #15: A2-U4 "Preferences and comparison" (content 1.8.0, `bb1f2e6`)

**Lessons 48–52**, starting after `a2_u3_l5`:

| Lesson | Content |
|---|---|
| `a2_u4_l1` Me gusta… | me gusta / me gustan, ¿Te gusta…?, le gusta (a + person + le), me encanta, no me gusta nada, a mí también / tampoco, trabajar en equipo |
| `a2_u4_l2` ¿Cuál prefieres? | prefiero (e→ie), ¿Cuál prefieres? vs ¿Qué?, ese / esa, el modelo, el color; negro / blanco / azul, with agreement |
| `a2_u4_l3` Más rápido, más barato | más / menos … que, tan … como, mejor que, peor; rápido, lento, grande, pequeño |
| `a2_u4_l4` En mi opinión | creo que, en mi opinión, me parece / parecen, estoy de acuerdo / no…, tienes razón, depende, interesante, la ventaja |
| `a2_u4_l5` Dos ofertas | la oferta, el proveedor, el precio, la calidad, la desventaja, el más barato, la mejor opción, recomiendo, aunque |

**Every lesson includes:**
- listen-choose, listen-pick, typing, ordering, dictation, fill-in, matching;
- a situational reply, a reading and a listening choice, and listen-and-repeat;
- `explain_ar` on every fill and every grammar choice;
- work items and FSRS cards.

**Dialogues.** There are three, each rated "very easy" or "appropriate" right
after its lessons:
- `dlg_a2_gustos`: choosing a team phone;
- `dlg_a2_portatiles`: comparing two laptops;
- `dlg_a2_ofertas`: two supplier offers and a recommendation.

To keep them there, I replaced a few untaught words (diferencia, entre, aun
así). I also added examples that teach the forms the dialogues need:
colores, parecen, barata.

**Checkpoint `chk_a2_u4`:**
- 12 questions covering 3 can-dos;
- grammar 5, listening 3, reading 2, writing 2, vocabulary 1;
- 3 questions play dialogue sentences;
- options are shuffled.

**Verbs:** 6 new, 45 in total.
- **preferir:** entered by hand (prefiero; prefirió, prefirieron).
- **creer:** regular in the present, irregular past entered by hand (creyó).
- **parecer:** parezco; regular in the past.
- **recomendar:** e→ie; regular in the past.
- **gustar and encantar:** checked by machine.

### Answer evaluation (existing engine, now tested on this content)

- "Me gusta los idiomas" is diagnosed as a wrong verb form, with the correct
  form `gustan`.
- "a mi también" is an accent-meaning error: mí is a pronoun, mi means
  "my". A missing accent only on también is accepted with a reminder.
- "la más buena opción" and "más rápido como" are rejected.

### Verification

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| content validator | OK: 52 lessons, 442 items, 899 graded, 28 dialogues, 14 assessments, 45 verbs |
| `flutter test` | **379 passed** (368 + 10 in `a2_u4_preferences_test` + completing A2-U4 in `a2_units_test`) |
| screenshots | 07 and 22 regenerated |

## Questions for ChatGPT

1. The unit says "el móvil" (Spain). The Latin American "el celular" is not
   mentioned yet. Should it get a note?
2. Lesson 51 avoids "no creo que" + subjunctive and points to B1. Is that
   right for A2?

## Proposed next step

1. **A2-U5 "Simple work conversations"**, the last A2 unit: messages, emails
   and follow-up, combining the tenses taught so far.
2. **Then the A2 level assessment `lvl_a2`**, in the same model as `lvl_a1`.

I will not merge #14 or #15. That is the owner's decision.

---

# Previous handoff (PHASE3-004, still awaiting review)

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE3-004
updated_at_utc: 2026-11-23T12:00:00Z
review_requested_for_sha: 941c18b (application code 941c18b, 0a2b18b, a6c1ad9 and 7330136)
branch: feat/a2-u3-future
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/14
last_review_acknowledged: REVIEW-015
project_status: A2_U1_U2_MERGED__A2_U3_IN_REVIEW__DEVICE_AND_NATIVE_QA_PENDING

## REVIEW-015 acknowledged; PR #13 merged

The owner asked in this session to merge #13. Before merging I checked:

- the head was still `8d89aae`, the SHA approved in REVIEW-015;
- CI run 44139749592 was green (353 tests, APK);
- the PR was `mergeable_state: clean`.

It was merged with a normal merge as **`bb4c4b9`**
(`bb4c4b907ffc44703f4a5928a4376ca8fc990d54`).

## P3 from REVIEW-015 — fixed (`7330136`)

- `answer_evaluator.dart` adds `finalStressNonVerbs`: bebé, canapé, carné,
  chalé, cliché, comité, consomé, dominó, puré.
- For those words a missing final accent is still `accentMeaning`, because
  it is a different word. The explanation no longer mentions tense.
- **New validator rule.** Every answer word of 5+ letters that ends in a
  stressed é/ó must be one of:
  - a verb form from the reference (present or past);
  - a word from an item whose part of speech is a verb;
  - a listed non-verb.
- The rule checks items, fill, respond and checkpoint answers. New content
  therefore cannot reach the tense explanation by mistake.
- **Tests.** `a2_u3_future_test` covers:
  - the evaluator: comité gets no tense text, habló still does;
  - 4 negative content cases: parqué in an item, in a respond answer, and
    plató in a checkpoint answer;
  - one positive case: comité, which is listed.
- **One scoped test.** The A2-U2 compatibility test now asserts that the
  verb file is valid without past forms. The only remaining issues are the
  new rule's: "terminó" loses its source once the past forms are removed.

## Ambiguous distractors: fixed in `941c18b`

Codex found a pattern on #14 and #15: a fill-in distractor that is also valid
Spanish. I checked every A2-U3 fill-in for it. Five offered a correct
alternative:

- no podemos
- ¿quedan…?
- luego van a empezar
- piensa visitar
- empezó… y termina

Their distractors are now non-finite forms (poder, quedar, quedado,
empezar, ir, yendo), or a subject fixes the person (yo pienso).

## Codex review on PR #14: fixed in `0a2b18b`

The Codex bot raised a P2 that I checked and agree with. The A2-U3 note
taught that `ir a` cannot follow conditional `si`, but RAE gives "Si vas a
salir, ponte el abrigo" as valid. What `si` excludes is the simple future.

- The notes now say that, with an `ir a` example.
- The distractors in the lesson choice, the fill and `chk_a2_u3.q10` were
  `fue` / `va a ir`. They are now `irá` / `ir`, which are unambiguously
  wrong.
- The thread is answered and resolved. 368 tests still pass.

## PR #14: A2-U3 "Plans and the future" (content 1.7.0, `a6c1ad9`)

**Lessons 43–47, starting after `a2_u2_l5`:**

| Lesson | Content |
|---|---|
| `a2_u3_l1` ¿Qué vas a hacer? | ir a with every person, contrasted with the past and present; esta tarde, la semana que viene, el próximo lunes, dentro de, pronto |
| `a2_u3_l2` ¿Quieres venir? | ¿Quieres venir? / ¿Te apetece…? (with a Spain vs LatAm note); me encantaría, vale, no puedo, otro día, tengo planes; pensar e→ie + infinitive; la comida de trabajo |
| `a2_u3_l3` ¿Quedamos el lunes? | quedar; ¿Te / Le viene bien…? (agreement with the appointment); mejor, cambiar, confirmar, la videollamada, a primera hora, propongo |
| `a2_u3_l4` La agenda de la semana | present for timetables (sale, empieza, termina); la feria, el horario, la fecha, el plazo, antes de, hasta las |
| `a2_u3_l5` El plan del proyecto | el plan, el objetivo, la fase, la entrega, el presupuesto, le mando, si todo va bien, a finales de mes, la próxima reunión |

**Each lesson has:**
- listen-choose, listen-pick, type, order, dictation, fill, match;
- a reply to a situation, a reading or listening task, and listen-and-repeat;
- `explain_ar` on every fill and grammar choice;
- work items, and FSRS cards (two per item).

**Dialogues.** All three are rated "very easy" or "appropriate" right after
their lessons:
- `dlg_a2_invitacion` — an invitation, politely declined;
- `dlg_a2_cita_cliente` — arranging a meeting with a client, which becomes a
  video call;
- `dlg_a2_proyecto` — a project plan, delivery and quote.

**Checkpoint `chk_a2_u3`:**
- 12 questions, 3 can-dos, 5 skills (grammar 4, listening 3, reading 2,
  writing 2, vocabulary 1);
- 3 questions play dialogue sentences;
- options are shuffled.

**Verbs:** 7 new, 39 in total.
- pensar is entered by hand (present e→ie; regular past).
- proponer is entered by hand (propongo / propuse).
- quedar, cambiar, confirmar and mandar are machine-checked.
- pasar was added for "¿Qué pasó?" in A2-U2.

### Verification

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| content validator | OK: 47 lessons, 397 items, 799 graded, 25 dialogues, 13 assessments, 39 verbs |
| `flutter test` | **368 passed** (353 + 14 in `a2_u3_future_test` + A2-U3 completion in `a2_units_test`) |
| screenshots | 07 (A2 progress 0/15) and 22 regenerated |
| debug APK | built by the PR CI (no Android SDK here) |

## Known engineering issues

1. **Short words stay lenient.** The final-accent rule still applies only to
   words of 5+ letters, so pasó/paso and bebé/bebe are still accepted with
   an accent reminder. Lowering the threshold would also catch café/cafe in
   A1. That would be a policy change for the owner and reviewer.
2. **Short irregular forms are not diagnosed.** "van" for "vamos" is marked
   wrong, but the wrong-form diagnosis does not explain it, because the
   words are too short for the inflection rule.

## Questions for ChatGPT

1. Should the final-accent threshold drop to 4 letters from A2 on (pasó),
   with café as a listed exception?
2. Is the Spain-centred vocabulary acceptable at this level, with the
   LatAm equivalents given in notes? Examples: vale, ¿Te apetece?, la
   comida = lunch.

## Proposed next step

A2-U4 "Preferences and comparison": gustar / encantar / preferir,
comparatives (más / menos … que, mejor / peor), and opinions (creo que,
para mí).

I will not merge PR #14; that is the owner's decision.

---

# Previous handoff (PHASE3-003)

owner: Claude Code
implementer: Claude Code
handoff_status: MERGED_AS_bb4c4b9
handoff_id: PHASE3-003
updated_at_utc: 2026-11-17T21:00:00Z
review_requested_for_sha: b8d4d17 (application code 7bfbae6, on 10ac581 and 86dff95)
branch: feat/a2-u2-past
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/13
last_review_acknowledged: REVIEW-014
project_status: A2_U1_MERGED__A2_U2_IN_REVIEW__DEVICE_AND_NATIVE_QA_PENDING

## REVIEW-014 acknowledged, and PR #12 merged

REVIEW-014 approved PR #12 head `3196441` (CI run 44105207452: 333 tests,
APK). The owner then explicitly authorized the merge. Before merging I
checked the following:

- **Head:** still `3196441`.
- **Mergeability:** `mergeable_state: clean`.
- **CI:** both check runs successful on that exact head.
- **REVIEW-012 fixes present:** the `displayedChoices` shuffle in
  `assessment_screens.dart`, and no `cobramos` left in `dialogues/a2.json`.

The PR was marked ready and merged with a normal merge commit. No
force-push was used.

| | |
|---|---|
| Merge commit | **`004e54d`** (`004e54d66f955b6d4b3b9b3ff9f84e11c7b6f15f`) |
| On main | `units/a2_u1.json`, `dialogues/a2.json`, `assessments/a2.json`, `a2_units_test`, `assessment_order_test`; content 1.5.0 |

The REVIEW-014 release gates still stand: device QA and native Spanish QA
for A2-U1.

## PR #13: A2-U2 "The past — what happened?" (content 1.6.0)

Branch `feat/a2-u2-past`, created from `004e54d`. **Not to be merged without
owner authorization for this PR.**

### Commits

| SHA | Change |
|---|---|
| `86dff95` | `answer_evaluator.dart`: final é/ó accent rule, past-tense endings in the verb-form diagnosis |
| `10ac581` | `models.dart`, `content_parser.dart`, `content_validator.dart`, `verbs_view.dart`: optional past tense |
| `7bfbae6` | Content 1.6.0 and tests |
| `b8d4d17` | Docs and screenshots |

`10ac581` was also verified on its own in a separate worktree, without the
A2-U2 data.

### Lessons 38–42

The lesson breakdown is as specified. One refinement: the **-ar** past comes
first (38). **-er/-ir** follow in 39. The **yo spelling changes** come in 40.
**Irregular forms first appear in 41**: no lesson before 41 practises or
assesses ir/ser, hacer or tener in the past.

| Lesson | Content |
|---|---|
| `a2_u2_l1` Ayer trabajé mucho | trabajé / trabajó / hablé / llamé / terminé, ¿Hablaste…?; ayer, anoche, el lunes pasado |
| `a2_u2_l2` Mi último fin de semana | salí, volví, comimos, visité, descansé; primero, después, luego, al final; a reading story |
| `a2_u2_l3` Un día de trabajo | llegué, empecé, revisé, envié, preparé, terminamos; esta mañana; ya / todavía no; a work-update email |
| `a2_u2_l4` Mi último viaje | fui, fue, fuimos, hice, hizo, tuve; el viaje, el vuelo, el año pasado; a travel narrative |
| `a2_u2_l5` ¿Qué pasó con el cliente? | ¿Qué pasó?, se quejó, expliqué, solucioné, le escribí, al día siguiente, por eso, el seguimiento, ahora todo funciona |

**Every lesson has:**

- **Practice and production:** listen-choose, listen-pick, type, order,
  dictation, fill, a situational reply, reading or listening comprehension,
  and listen-and-repeat.
- **Feedback:** `explain_ar` on every fill and grammar choice.
- **Work and review:** work-tagged items, and FSRS cards (2 per item).

**8 grammar notes:**

- `g_pret_ar` and `g_pret_er_ir` (the regular past);
- `g_past_markers` (time words for the past);
- `g_sequence` (ordering events);
- `g_pret_spelling` (yo spelling changes);
- `g_ya_todavia` (ya / todavía no; also notes the Spain vs Latin America
  preference for the perfect);
- `g_pret_irregular` (ir/ser, hacer, tener, estar);
- `g_past_vs_present`.

### Dialogues and checkpoint

**Dialogues:**

| Dialogue | Lessons | Situation |
|---|---|---|
| `dlg_a2_finde` | 38–39 | The weekend |
| `dlg_a2_jornada` | 40 | A workday update |
| `dlg_a2_viaje` | 41–42 | A trip, then a client complaint |

- All three are rated "very easy" or "appropriate" right after their
  lessons, with no new grammar.
- They have 5–6 questions each, including speaker and dictation questions.

**Checkpoint `chk_a2_u2`:**

- 12 questions covering 3 can-dos and 5 skills: grammar 4, listening 3,
  reading 2, writing 3, vocabulary 1.
- 3 questions play dialogue sentences.
- The options are shuffled per attempt (the REVIEW-012 fix).
- The typed questions (volví, envié, fui) reject a missing final accent.

### Engineering changes

**Verb reference:**

- `Verb.preterite` and `Verb.preteriteRegular` are added. The latter defaults
  to `regular`; its JSON key is `preterite_regular`.
- `Verb.regularPreterite` applies the -ar and -er/-ir endings, plus the yo
  spelling changes -car → qué, -gar → gué, -zar → cé.
- **Validator:** when past forms are given, all six persons are required and
  must be Spanish-only with known keys. A regular past must match the rule
  exactly.
- **Backward compatibility:** files without past forms still validate. A test
  removes every `preterite` key to prove it.
- **Data:**
  - all 32 verbs now have past forms, 10 of them new verbs;
  - 7 irregular pasts are entered by hand: ser, ir, estar, tener, querer,
    poder, hacer;
  - 6 verbs are irregular in the present but regular in the past: enviar,
    devolver, comprobar, salir, volver, empezar.
- **Library:** a "pretérito indefinido" table appears under the present
  table, with audio per form and keys `verb-past-<id>-<person>`. The present
  keys are unchanged.

**Evaluator — `isFinalStressPair`:**

- In a word of **5 or more** letters, a missing or extra final é/ó is now
  `accentMeaning`, not "accents only". Examples: hablo/habló,
  trabaje/trabajé, envio/envió. The feedback says the accent changes tense
  or person.
- Short words keep the lenient rule (café/cafe, fue/fué).
- Past endings are added to the inflection set, so "hablaste" for "hablé" is
  diagnosed as `grammarForm`.
- Every A2-U2 typed past form ending in é/ó is tested to reject its
  unaccented twin.

### Tests

New `test/a2_u2_past_test.dart`, 19 tests:

- curriculum and order;
- activity coverage per lesson;
- grammar before assessment;
- unlocking after `a2_u1_l5`;
- `regularPreterite` and all verb forms;
- backward compatibility;
- 4 validator negatives;
- verb table with audio;
- 4 evaluator tests;
- dialogue difficulty;
- checkpoint skills and feedback;
- grading of wrong form and missing accent;
- shuffle;
- persistence across a DB reopen and a retry;
- FSRS cards for a completed lesson, with earlier progress unchanged.

**Changed tests:**

- `a2_units_test`: both A2 units are available and every lesson of both is
  completed through the UI.
- `verbs_and_level_test`: the verb table shows both tenses. "hablamos" now
  appears twice, because nosotros has the same form in the present and the
  past.

### Verification

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| content validator | OK: 42 lessons, 352 items, 699 graded activities, 22 dialogues, 12 assessments, 32 verbs |
| `flutter test` | **353 passed** (333 on main + 20) |
| screenshots | 07, 22, 23 regenerated (A2 progress 0/10; verb table with past) |
| debug APK | **built by PR CI only**; this environment has no Android SDK |

## Known engineering issues

1. **Accent rule is broad.** It fires for any 5+ letter word with a final
   é/ó, not only verbs. Today's content has no such non-verb, and a word
   like bebé/bebe is also a real meaning difference. If a future noun such
   as "puré" needs lenience, it would need a word list.
2. **-í pasts stay lenient.** comí/comi and salí/sali are still accepted
   with an accent reminder, because the unaccented forms are not other
   words.
3. **No lemmatisation in the difficulty estimator.** Past forms count as
   known only if they appear in taught items or examples. I added a few
   examples (¿Trabajaste…?, ¿Saliste…?, ¿Enviaste…?) for that.
4. **A2-U1 test data:** the A2-U1 tests are unchanged.

## Questions for ChatGPT

1. Is the 5-letter final-é/ó rule the right trade-off, or should it be
   limited to forms listed in the verb reference?
2. Should `ya` + pretérito carry a stronger Spain-vs-LatAm note, or is the
   current one enough at A2?
3. Should lesson 41 also practise `estar` in the past (estuve)? It is only
   in the grammar note and the reference.

## Not done or claimed

- Device QA.
- Native Spanish QA. Everything stays `author_reviewed`.
- A2-U3 to A2-U5 and the A2 level assessment.
- The A1→A2 policy is unchanged.

## Proposed next step

A2-U3 "Plans and future":

- ir a + infinitive at A2 depth;
- quedar / quedar con for arranging meetings;
- the present for scheduled events;
- time expressions for the future.

It would be built the same way: about 5 lessons, 3 dialogues and
`chk_a2_u3`.

I will not merge PR #13; the owner decides.

---

# Previous handoff (PHASE3-002)

owner: Claude Code
implementer: Claude Code
handoff_status: MERGED_AS_004e54d
handoff_id: PHASE3-002
updated_at_utc: 2026-11-17T19:30:00Z
review_requested_for_sha: e3e948d
branch: claude/amazing-hypatia-7mt4rs
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/12
last_review_acknowledged: REVIEW-012
project_status: A2_U1_IN_REVIEW__REVIEW_012_FIXES_READY__DEVICE_AND_NATIVE_QA_PENDING

## REVIEW-012 — findings and fixes (code SHA `e3e948d`)

### P1 — assessment options always had the answer first → fixed

**Engine** (`lib/core/assessment/assessment_engine.dart`):

- `attemptSeed(startedAt)` gives the attempt's seed.
- `displayedChoices(q, seed)` returns a shuffled copy of `q.choices`:
  - it is seeded by the attempt and the question id (`stableHash`);
  - the content list is never mutated.

**Screen** (`assessment_screens.dart`):

- The options are shown in that order.
- The order is fixed for the whole attempt. It survives rebuilds, selection,
  next/back and listening, because the seed is `_startedAt`.
- A new attempt usually gets a different order.

**Grading is unchanged.** It still compares the chosen **text** with
`choices[answer]`, so stored answers and results mean the same as before.
This applies to every checkpoint and level assessment: Pre-A1, A1 and A2.

**New `test/assessment_order_test.dart`:**

- every shipped choice question shows a permutation of its options, stable
  for one seed, with content unchanged;
- the correct option takes more than one position across seeds;
- "always the first option" fails at least one choice on **every** shipped
  assessment, and is right on fewer than half of all choices for a fixed
  seed (content order made that 100%);
- answering by text still grades fully correct;
- widget, `chk_a2_u1`:
  - the screen shows exactly `displayedChoices(q, attemptSeed(start))`;
  - the same order holds after selecting, next and back;
  - three attempts at different times do not all share one order.

**Brittle tests:** `assessment_flow_test` and the screenshot test no longer
tap `assessment-option-${q.answer}`. They tap the option by its text
(`tapOption`).

### P2 — ambiguous `cobramos` → rewritten

`dlg_a2_reclamacion.t7` now reads: «Sí, hay un error: la factura tiene el
servicio dos veces.» It uses only taught constructions.

- The Arabic and English are updated: "الخدمة مذكورة في الفاتورة مرّتين".
- Question q3's correct option now reads "الخدمة مذكورة مرّتين".
- `cobrar` is removed from the dialogue's vocabulary list.
- The line still passes `difficulty_test`.

The other uses of cobrar in the unit are in the present ("me cobran", "el
técnico cobra"). Native review is still pending.

### P3 — progression gate → unchanged, as requested

A2 still requires only the last A1 lesson. It does not require the A1 level
assessment. The path change only keeps the level assessment visible. A
pass gate stays the owner's decision.

## Verification (local, Flutter 3.50.0)

| Check | Result |
|---|---|
| format | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| content validator | OK |
| `flutter test` | **333 passed** (328 + 5 in `assessment_order_test`) |
| `flutter test test_screenshots` | see below |

**Screenshots:** `07_progress`, `21_checkpoint_question` and
`22_checkpoint_result` were regenerated.

- 07: progress now lists A2 (0 / 5). This came from the A2-U1 commit, which
  had not refreshed the goldens.
- 21: the correct option "perro" is no longer first.
- 22: the result screen.

## Still not done or claimed

- Device checks: checkpoint option order, path expansion after A1, and A2
  dialogue TTS.
- Native Spanish review of A2-U1.
- A2-U2 onward, and the A2 level assessment.

I will not merge; merging is the owner's decision.

---

# Previous handoff (PHASE3-001)

owner: Claude Code
implementer: Claude Code
handoff_status: SUPERSEDED
handoff_id: PHASE3-001
updated_at_utc: 2026-11-17T18:00:00Z
review_requested_for_sha: 2d2700b
branch: claude/amazing-hypatia-7mt4rs
pull_request: (draft PR from this branch to main; link in the PR itself)
last_review_acknowledged: REVIEW-011
project_status: A2_STARTED__A2_U1_IN_REVIEW__DEVICE_AND_NATIVE_QA_PENDING

## Scope: the first A2 unit (Phase 3 begins)

The owner asked, in this session, to start A2. This PR adds **A2-U1
"Services and everyday transactions"** and one small path fix. It does
not touch the REVIEW-009/011 code.

### Content 1.5.0

**Five lessons (33–37), chained after `a1_u6_l4`:**

| Lesson | Focus |
|---|---|
| `a2_u1_l1` En el banco | quisiera (polite request); poder o→ue (puedo / puede); cuenta bancaria, cajero, firmar |
| `a2_u1_l2` En correos | tener que + infinitive; paquete, sobre, dirección, código postal; ¿Cuánto tarda? |
| `a2_u1_l3` No funciona | no funciona; roto/rota with estar; object pronouns lo / la; desde ayer + present |
| `a2_u1_l4` Una reclamación | el problema (masc.); error, cobrar, devolver (o→ue); ¿Me puede ayudar? (me / le) |
| `a2_u1_l5` Atención al cliente | provider's side: disculpe las molestias; present for immediate promises; le envío…; comprobar |

- 43 items and 6 grammar notes. Every lesson has items marked `work`.
- **3 dialogues:** `dlg_a2_banco`, `dlg_a2_averia`, `dlg_a2_reclamacion`.
  - On first run the difficulty estimator rated two of them "challenging".
  - Causes: untaught words (servicio, nuestra, revisa), and turns averaging
    over 10 words.
  - Fix: the words were rewritten and the long turns split. All three now
    pass `difficulty_test`.
- **Checkpoint `chk_a2_u1`:**
  - 12 questions, 3 can-dos, 5 skills;
  - 3 questions play dialogue sentences;
  - every grammar question has `explain_ar`.
- **Verb reference** grows from 16 to 22 verbs:
  - abrir, sacar, arreglar and cobrar are regular, checked against the
    conjugation rules;
  - devolver and comprobar (o→ue) are entered by hand;
  - poder and tener now also link to the A2 lessons that use them.
- **One A1 change:** `revisar` gets `"syn": "check"`, shared with
  `comprobar`, so the two near-synonyms are never shown as each other's
  wrong answer. The item ID is unchanged.

### Path fix — `lib/features/path/path_screen.dart`

**Before:** once A2 had lessons, finishing A1 made the path expand A2
(where the next lesson is) and collapse A1. The A1 level assessment tile
was hidden. The existing `verbs_and_level_test` caught this.

**Now:** a level whose lessons are all complete stays expanded until its
level assessment has at least one attempt.

## Verification (local, Flutter 3.50.0)

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed` | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| `dart run tool/validate_content.dart` | OK: 37 lessons, 306 items, 598 graded activities, 19 dialogues, 11 assessments, 22 verbs |
| `flutter test` | **328 passed** (323 on main + 5 in `a2_units_test`) |
| `build_runner` | `database.g.dart` unchanged |

`a2_units_test` checks:

- lesson order and prerequisites;
- every A2-U1 lesson completed through the real UI with full marks and no
  error records;
- the checkpoint can be fully answered;
- dialogues unlock inside the unit;
- regular vs hand-entered verbs;
- the synonym group.

`listening_content_test` now expects dialogues for pre_a1, a1 and a2.

## Not done or claimed

- **Language review:** native Spanish review of A2-U1. Everything is
  `author_reviewed`. Please check especially:
  - the register of `disculpe las molestias` and `le envío…`;
  - `cobramos` in `dlg_a2_reclamacion.t7`. It is ambiguous between present
    and preterite and is translated as past. The preterite is formally
    taught in A2-U2.
- **Device:** device checks of the new unit and the path change.
- **A2 app features (not started):**
  - A2-U2 to A2-U5 and the A2 level assessment;
  - the planned A2 features: stricter accent marking and less reliance on
    Arabic translation.
- **No gate on A2:** A2 does not require passing `lvl_a1`. The first A2
  lesson only requires the last A1 lesson, consistent with "checkpoints are
  evidence, not gates".

## Request for review

1. `assets/content/v1/units/a2_u1.json`, `dialogues/a2.json` and
   `assessments/a2.json`: check pedagogy, Spanish and Arabic.
2. The `PathScreen` expansion change.
3. `test/a2_units_test.dart`.

I will not merge; merging is the owner's decision.

---

# Previous handoff (PHASE1-014)

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-014
updated_at_utc: 2026-11-17T15:00:00Z
review_requested_for_sha: main after the PR #11 merge (application code unchanged since 9ddc13a / 9f86876 / 011fecb)
branch: main
last_review_acknowledged: REVIEW-010
project_status: PHASE_1_2_AND_A1_CONTENT_MERGED_BY_OWNER__REVIEW_OF_REVIEW_009_FIXES_PENDING__DEVICE_AND_NATIVE_QA_PENDING

## Merged with the owner's explicit authorization

On 2026-11-17 the owner said, in this session, to merge everything. PRs
#7 → #8 → #9 → #10 → #11 were merged into `main` in that order, using merge
commits and no force-push. Each stacked PR was retargeted to `main` after its
predecessor merged and updated with `main` first. The only conflict each
time was this file, where the branch's own handoff was kept. The full test
suite was run locally before every merge.

| PR | Merge commit | Contents |
|---|---|---|
| #7 | `bc9692f` | 1.2B checkpoints + REVIEW-008/009 fixes |
| #8 | `8b9b97b` | 1.2C answer diagnosis, difficulty estimator |
| #9 | `afaca8c` | A1-U2/U3 |
| #10 | `dd57357` | A1-U4/U5 |
| #11 | (this merge) | A1-U6, verb reference, A1 level assessment |

**Honest status**

- **REVIEW-009 fixes not yet reviewed.** REVIEW-010 kept CHANGES_REQUESTED
  for the REVIEW-009 P2/P3. Both were fixed afterwards (`9ddc13a`,
  `9f86876`, handoff PHASE1-013, all five PR CIs green). They have **not**
  been independently re-reviewed; the owner chose to merge before that
  review. Please review them on `main`. Any finding will be fixed in a new PR.
- **Not done or claimed:**
  - native Spanish review;
  - device acceptance (Phase 1.1 and 1.2);
  - A1 "completion" in any certification sense.

## Request for review

1. The REVIEW-009 P2 fix: `lib/core/speech/delivery_log.dart`, the
   `DialogueQuestionsScreen.onAttempt` change, and
   `ProgressRepository.recordAttempt(measured:)`.
2. The REVIEW-009 P3 fix: `AppDatabase._ensureOneAnswerPerQuestion`.
3. CI on `main` after this merge.

---

# Previous handoff (PHASE1-012, PRs #10/#11)


owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-012
updated_at_utc: 2026-11-17T13:00:00Z
review_requested_for_sha: 011fecb
branch: feat/a1-u6-final
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/11 (stacked: #7 → #8 → #9 → #10 → this)
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

GitHub Actions: PR #11 run 44066977854 on `dcfd4bf` — format, analyze, content, generated code, secrets: success, **318 tests passed**; Android debug APK: success. PR #10 run 44065354477 on `09c2991` — success (tests and APK).

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
