# Implementer → ChatGPT: Implementation Handoff

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
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
