# ChatGPT → Implementer: Independent Engineering Review

owner: ChatGPT
review_status: BLOCKED_PENDING_CI
review_id: REVIEW-016
updated_at_utc: 2026-11-23T08:23:51.904Z
reviewed_pr14_head_sha: fb664aafb536644413e24c6ee3550860208e5c05
reviewed_pr15_head_sha: 5254cf4e3da0cf19bb8d1922b776ac69b4ff6425
reviewed_pr16_head_sha: 698de815a5968d1adfac24d8cefc253acff077a7
reviewed_pr17_head_sha: 4c2f3b56d7060ae7bcebaea8123430a1879c88e9
reviewed_pull_requests: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/14 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/15 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/16 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/17
pr14_review_status: APPROVED_WITH_RELEASE_GATES
pr15_review_status: APPROVED_WITH_RELEASE_GATES
pr16_review_status: APPROVED_WITH_RELEASE_GATES
pr17_review_status: PENDING_EXACT_HEAD_CI
project_acceptance: A2_CONTENT_PRESENT_IN_OPEN_STACK__NATIVE_SPANISH_AND_DEVICE_QA_PENDING

## REVIEW-016 — A2-U3/U4/U5 + A2 final assessment (#14 → #15 → #16 → #17)

Independent milestone review following REVIEW-015. Read main's bridge README, previous ChatGPT reviewer report and implementation handoff; explicitly fetched `AI_BRIDGE/CLAUDE_STATUS.md` at **each** PR head: PHASE3-004 (#14), PHASE3-005 (#15), PHASE3-006 (#16), and PHASE3-007 (#17). Their base branches are stacked in the intended order: #14 → #15 → #16 → #17, with #14 based on main, after PR #13 merged. All four are open, not merged. Latest main SHA `bb4c4b907ffc44703f4a5928a4376ca8fc990d54`, with green post-merge CI. Main implementation handoff is stale relative to these PR heads.

### Scope independently examined

- **#14 A2-U3**: Actual PR changed-path diff; `units/a2_u3.json`, `assessments/a2.json`, `dialogues/a2.json`, new verb entries, `answer_evaluator.dart`, `content_validator.dart`, tests `a2_u3_future_test.dart` and `a2_units_test.dart`. Five lessons each with 9 items, 31–32 activities, 3 objectives and sequential prerequisites after A2-U2; three linked dialogues and a 12-question checkpoint. The current content includes the corrected `si` / `ir a` explanation and disambiguated fill distractors. The REVIEW-015 P3 fix recognizes listed final-stress non-verbs so the diagnostic text is no longer universally a verb-tense explanation. **Exact-head CI independently verified successful**: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45135196660 — both test and APK jobs passed, analyzer and validator clean, **368 tests** in log. **Decision: APPROVED_WITH_RELEASE_GATES for inspected engineering scope**; not a release or permission to merge.
- **#15 A2-U4**: Actual PR changed-path diff; `units/a2_u4.json`, linked dialogues and checkpoint, verb data and `test/a2_u4_preferences_test.dart`. Five consecutive lessons each with 9 items, 31 activities, 3 objectives, multiple guided and production exercise types; three dialogues and 12-question checkpoint. Confirmed corrections described in branch handoff include accepting `¿Qué prefieres?` as valid and narrowing ambiguous fill distractors. **Exact-head CI independently verified successful**: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45135403813 — test and APK jobs passed, analyzer and validator clean, **379 tests** in log. **Decision: APPROVED_WITH_RELEASE_GATES for inspected engineering scope**.
- **#16 A2-U5**: Actual PR changed-path diff; `units/a2_u5.json`, dialogues and checkpoint, seven added verbs, `test/a2_u5_work_test.dart`. Five consecutive lessons, each with 9 items, 31 activities, 3 objectives, typed/listening/production practice; three dialogues and 12-question checkpoint. Checked the recent correction directly at PR #16 head `698de815`: `dlg_a2_mensajes.t5` now reads `Todavía no. Te aviso esta tarde.`, not the invalid future-oriented `Te aviso cuando está listo.`; companion lesson messages now say `Te aviso en diez minutos.`. **No new confirmed P0/P1/P2 defect in inspected changed content.** Claimed local **389 tests** are not yet an exact-head GitHub CI success: run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45137409490 was **in progress** at check, with test and APK jobs not completed. **Decision: PENDING_EXACT_HEAD_CI**; verify both jobs and read test count/log before engineering approval.
- **#17 A2 level assessment**: Actual PR diff; `assessments/a2.json` contains `lvl_a2`, 25 questions, five can-dos covering every A2 lesson, five measured skills and five dialogue-linked listening prompts, without pretending to measure speaking. `test/a2_level_test.dart` verifies coverage, answer grading, choice shuffling, SQLite persistence, locked-until-completion logic and path access. Assessed the actual question text and answer choices, including meaning-accent rejection for `llegué` and `está`. **PR #17 was updated DURING this review** from head `217e3357` to current `a5c2fa4` to incorporate the missing #16 language corrections. Independently re-fetched `dlg_a2_mensajes.t5` at the **new** #17 head and confirmed the corrected `Te aviso esta tarde.` and absence of `cuando` constructions in A2-U5. Do not repeat the already resolved branch divergence issue. Prior run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45137094475 at old head `217e3357` had **394 passing tests** and analyzer/validator clean but APK job **cancelled**. The new exact-head run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45137637683 was still **in progress**, and the passing *old-head* tests cannot be treated as final-head CI evidence. **Decision: PENDING_EXACT_HEAD_CI**, no new confirmed P0/P1/P2 in inspected assessment source.

### REVIEW-016 live follow-up — new #17 code and completed #16 CI (2026-11-23T08:23:51.904Z)

This is a focused update to the same review, **not a redo of unchanged lesson content**.

- **PR #16 exact-head CI now GREEN.** Run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45137409490 completed **success** at unchanged head `698de815a5968d1adfac24d8cefc253acff077a7`. Independently read the test job log: `flutter analyze` clean, content v1.9.0 validated with 57 lessons, 31 dialogues, 15 assessments, 52 verbs; **389 tests passed**. The Android debug APK job also completed successfully. **PR #16 is now APPROVED_WITH_RELEASE_GATES** at that exact head, subject to earlier stacked PR merge/rebase verification and owner authorization.
- **PR #17 advanced to a genuinely new app code SHA, head `4c2f3b56d7060ae7bcebaea8123430a1879c88e9`.** Compared with previously inspected `a5c2fa4`: only `assets/content/v1/assessments/a2.json`, `assets/content/v1/units/a2_u1.json`, and the implementer status changed. Individually re-fetched the changed JSON at the current head and confirmed Codex's identified **ambiguous distractor** has been corrected: `lvl_a2.q1` now specifies in Arabic that the learner is asking the *gentleman to sign*, retains `¿Puede firmar aquí, por favor?`, and uses `poder/podido` rather than the valid alternative `puedo`; the existing A2-U1 `Señor, ¿___ firmar aquí?` fill also now uses `puede/poder/podido`. The former `puedo` option was legitimately possible as "May I sign here?" and should not have been a forced wrong answer; the new wording and distractors resolve the ambiguity in inspected content.
- **PR #17 already incorporates PR #16's corrected `Te aviso esta tarde` dialogue and `Te aviso en diez minutos` examples; the previously observed outdated `cuando está/cuando llego` forms are absent** on the latest #17 head.
- **PR #17 CI is NOT yet fully green:** new exact-head run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/45137924949 was `in_progress` at the last check. The earlier `394 tests passed` was on a superseded head with a cancelled APK job, and therefore does not establish current-head release/build readiness. Read the full exact-head test and APK logs on completion; request a new run if cancelled again. No newly confirmed remaining P0/P1/P2 from the newly revised files.

**Updated decisions:** #14 APPROVED_WITH_RELEASE_GATES; #15 APPROVED_WITH_RELEASE_GATES; **#16 APPROVED_WITH_RELEASE_GATES**; #17 PENDING_EXACT_HEAD_CI. Overall remains `BLOCKED_PENDING_CI` until #17 has successful exact-head checks. Keep Spanish and physical-device acceptance separate. The authoring/implementation handoff should be refreshed to the new #17 code SHA by the implementer.

### Findings and acceptance boundaries

- **No newly confirmed P0, P1 or P2 code defect** in the inspected new application paths at the latest heads. A temporary P2 branch-divergence/Spanish grammar regression was independently reproduced at *old* #17 head, and verified **resolved** by new #17 head `a5c2fa4`; it is **not** an outstanding finding.
- **P3 language-policy question (not a blocking code defect):** `lib/core/learning/answer_evaluator.dart` retains an A1-era lenient treatment for short final stress (e.g., `pasó/paso`) and `finalStressNonVerbs` labels all omissions as meaning-changing even when an unaccented variant is not a valid distinct word. Clarify whether A2 ought to penalize these as incorrect with an accurate explanation; maintain explicit reviewed exceptions (e.g. `café`) and regression tests if changing policy. This is a future grading-policy/linguistic QA decision, not an excuse to change already accepted learner scoring silently.
- **P3 dialect coverage (content QA, not a merge-blocking code defect):** Review Spain-centric expressions `vale`, `¿Te apetece?`, `el móvil` and include useful Latin American equivalents/notes where appropriate for the user's learning goals. Native-qualified linguistic and pedagogical review should cover formal vs informal register, translations, verb forms, distractor ambiguity and listening prompts.
- **Physical Android release gates:** independently test on a real device dialogue TTS (including failure/no voice), listening measured evidence, checkpoint submissions and actual playback, sentence-level controls, path unlock, A2 level tile after all 25 lessons, restoring/retaining learner data, RTL/LTR rendering, verb playback and notification operation. Widget tests and fake speech do **not** establish real-device acceptance.
- **Academic scope:** 25 A2 lessons across five units, five checkpoints and one `lvl_a2` level assessment are present in the open stack; this means authored *content* coverage, not independently certified CEFR proficiency. A 25-question app-local test with no measured speaking does not constitute an official level exam.

### Exact next steps

1. Confirm run `45137409490` is fully green on PR #16 head `698de815` (format/analyze/content/tests and Android APK); verify actual test log. If head moves, use new exact SHA.
2. Confirm run `45137637683` is fully green on PR #17 head `a5c2fa4` (same checks); verify actual test log. If new work lands, check diff since this review.
3. After independent approval of current heads and explicit owner authorizations for **each** PR, merge #14, retarget/revalidate #15 onto main, then #16, then #17. Check that each later PR carries upstream fixes and its diff remains limited to its own milestone; re-run branch CI on retargeted HEAD as appropriate.
4. Keep implementation handoff accurately pointing to current code SHAs; current PR #17 handoff `review_requested_for_sha` predates its inherited synchronization corrections. Update the implementer-owned handoff in its branch, not this reviewer file.
5. Do not declare A2 device-approved or linguistically native-reviewed absent owner/human evidence; do not merge or release automatically.

No merge, deployment, force-push, secrets work, or edits to implementer-owned files performed.

---

# ChatGPT → Implementer: Independent Engineering Review

owner: ChatGPT
review_status: APPROVED_WITH_RELEASE_GATES
review_id: REVIEW-015
reviewed_pr: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/13
reviewed_pr_head_sha: 8d89aae2be3ead82bc63e3868997671106239d80
reviewed_application_sha: 7bfbae69fd78377cae294adb6e36f61779889bc2
responding_to_handoff: PHASE3-003
project_acceptance: A2_U2_ENGINEERING_CI_APPROVED__DEVICE_AND_NATIVE_SPANISH_QA_PENDING

## REVIEW-015 — New A2-U2 PR #13

**Decision: APPROVED_WITH_RELEASE_GATES for the inspected A2-U2 engineering scope; not release acceptance or permission to merge.** Read the three AI_BRIDGE files on main; main status is PHASE3-002 and stale. Discovered open PR #13 independently and read `AI_BRIDGE/CLAUDE_STATUS.md` on its actual head branch `feat/a2-u2-past`: PHASE3-003 READY_FOR_REVIEW. The head is `8d89aae2`, a status-only descendant of documentation commit `b8d4d17`, with latest application content commit `7bfbae6`. Compared branch against main `004e54d` (five commits, 22 changed paths). PR #12 is closed and merged, independently confirmed via GitHub issue state and main comparison.

**Inspected implementation:** Actual commit diffs `86dff95` (accent/inflection diagnostics), `10ac581` (optional past-tense verb model, parser, validator, reference UI) and `7bfbae6` (A2-U2 content, dialogue/checkpoint, tests); inspected branch source `lib/core/learning/answer_evaluator.dart`, `lib/core/content/models.dart`, `lib/core/content/content_validator.dart` and `test/a2_u2_past_test.dart`, plus PR comparison and checkpoint diff. Five new A2 lessons, three dialogues, a 12-question checkpoint, and conjugations for 32 verbs are present in the branch. Optional past forms are backward compatible by parser and tests. Regular preterite forms include -car/-gar/-zar yo spelling changes. Typed accent differences in long final é/ó forms now receive an incorrect/meaning-bearing verdict rather than an accepted accent reminder.

**Independent CI on exact current head:** GitHub Actions run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44139749592 is completed success; retrieved both job records (format/analyze/content/tests and Android debug APK: success) and the test job log explicitly reports **353 tests passed**, analyzer clean. An earlier run 44139603809 on `b8d4d17` was cancelled; it is superseded by the green head run. This is automated verification, not physical Android validation. Claude's local 353-test claim is independently corroborated by the head CI log.

**Findings:** No confirmed new P0/P1/P2 defect in the inspected changed paths. **P3 — future design caveat, not a blocking current-content defect:** `lib/core/learning/answer_evaluator.dart:isFinalStressPair` treats any word of at least five characters differing only in final é/ó as meaning-bearing and explains it as a verb tense/person difference. This can mislabel future non-verb examples. If future curriculum introduces such words, constrain this diagnosis using a reviewed set of verb forms or word-level exceptions; add regression tests for nonverbs before expanding the curriculum. Do not treat this caveat as a newly reproduced failure in shipped A2-U2 content.

**Pending gates:** Native Spanish linguistic/pedagogical review of A2-U1 and A2-U2; actual Android TTS/dialogue/checkpoint and verb-form playback, app restart/progress, Arabic RTL/Spanish LTR; owner approval for PR #13 merge. A2-U3 onward and A2 level assessment remain unimplemented. Codex bot's PR #13 review attempt failed due to usage limits; it is not evidence of a code defect, and no spending or retry was initiated.

No merge, deploy, force-push, or edit to implementer-owned files was made.

---

# ChatGPT → Implementer: Independent Engineering Review

owner: ChatGPT
review_status: APPROVED_WITH_RELEASE_GATES
review_id: REVIEW-014
updated_at_utc: 2026-11-17T14:46:17.022Z
reviewed_pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/12
reviewed_pr_head_sha: 3196441ba2664f7f6996e5d4b4af324bfa2a6e8a
reviewed_application_fix_sha: e3e948debef858c497a192ab0a8575f4a6535065
responding_to_handoff: PHASE3-002
project_acceptance: A2_U1_CODE_AND_CI_APPROVED__PHYSICAL_DEVICE_AND_NATIVE_SPANISH_QA_PENDING

## REVIEW-014 — PR #12 current-head CI verification and engineering verdict

**Decision: APPROVED_WITH_RELEASE_GATES for inspected A2-U1 implementation and REVIEW-012 corrections, not a device-tested release or authorization to merge.**

The prior REVIEW-013 verdict `BLOCKED` was specifically due to missing independently verified CI on the corrected code. That evidence has now arrived. GitHub PR #12 remains **open, draft, unmerged**. Its current head is `3196441ba2664f7f6996e5d4b4af324bfa2a6e8a`; the latest merge from main changed `AI_BRIDGE/CHATGPT_REVIEW.md` only and brought the previously published review into the branch. The A2 correction application commit `e3e948d` is in this head.

### Verified CI on exact current head

[GitHub Actions run 44105207452](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44105207452) is **completed: success** and matches exact head `3196441ba2664f7f6996e5d4b4af324bfa2a6e8a`. Independently retrieved both job records AND job logs:

- **Format, analyze, content, tests: success.** Log states `flutter analyze --fatal-infos` **No issues found**, content validation **OK — no issues found**, and **333 tests passed**.
- **Android debug APK: success.** Log confirms `✓ Built build/app/outputs/flutter-apk/app-debug.apk` and successfully uploaded `espanol-pro-debug-apk` artifact.

Thus the prior missing-CI concern in REVIEW-013 is **resolved**, not merely assumed from Claude's report.

### Corrected implementation reinspection

- **REVIEW-012 P1 — RESOLVED at code/test scope.** `lib/core/assessment/assessment_engine.dart` uses `displayedChoices(q, attemptSeed(_startedAt))` to shuffle a copy of the choices per question and attempt. `lib/features/assessment/assessment_screens.dart` renders the shuffled text, keeps order stable within an attempt and grades against original answer text. `test/assessment_order_test.dart` asserts stable permutations, varying positions, no always-first shortcut across shipped assessments, and navigation stability. No new defect identified in these paths.
- **REVIEW-012 P2 — RESOLVED at text scope.** In `dlg_a2_reclamacion.t7` the previous tense-ambiguous `le cobramos` is replaced with `la factura tiene el servicio dos veces`; Arabic and English translations and linked comprehension answer are updated. Naturalness/register are still pending qualified native Spanish QA.
- **REVIEW-012 P3 — unchanged owner decision.** A2 lesson 1 follows completion of the last A1 lesson, without requiring a passing A1 level assessment. Do not impose a pass gate without owner approval.

### Remaining independent acceptance gates (not CI failures)

1. **Real Android-device acceptance:** Install the current APK; verify Spanish TTS (including absent/failed voice), A2 dialogues/listening/checkpoint, stable randomized choices across navigation and new attempts, A1 level assessment visibility, Arabic RTL/Spanish LTR, app restart, saved progress and upgrade/migration as applicable.
2. **Qualified Spanish-language educational QA:** Review original A2-U1 dialogues, polite register, naturalness and translations (including the corrected invoice line); existing content is `author_reviewed`, not `native_reviewed`.
3. **Remaining roadmap:** A2-U2 onward, A2 level test and other planned phases are not implemented by PR #12. This approval is limited to A2-U1 and its fixes.
4. **Merge governance:** PR #12 stays draft until the owner chooses whether to merge. No deployment, release, merge, or edit to implementer-owned files was performed. If the PR head changes again, CI and relevant new code changes need fresh verification.

**Next to implementer:** Acknowledge REVIEW-014 in the next Claude-owned handoff. Do not re-open resolved REVIEW-012 P1/P2 solely due to old REVIEW-013. Offer the owner the APK and a concrete device QA checklist; preserve the draft PR and await explicit owner merge authorization.

---

owner: ChatGPT
review_status: BLOCKED
review_id: REVIEW-013
updated_at_utc: 2026-11-17T15:20:00Z
reviewed_application_sha: e3e948debef858c497a192ab0a8575f4a6535065
reviewed_pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/12
responding_to_handoff: PHASE3-002
project_acceptance: A2_U1_CODE_FIXES_INSPECTED_CI_AND_DEVICE_QA_PENDING

## REVIEW-013 — PR #12 updated code SHA `e3e948d`

**New handoff discovered on PR head despite stale main:** explicitly read `AI_BRIDGE/CLAUDE_STATUS.md` on `claude/amazing-hypatia-7mt4rs`; PHASE3-002 READY_FOR_REVIEW references `e3e948d`. Main still carries PHASE1-014. PR #12 remains open. Inspected actual diff of commit `e3e948debef858c497a192ab0a8575f4a6535065`, relevant assessment engine and screen source, new `test/assessment_order_test.dart`, and A2 dialogue changes. Do not conflate handoff claims with independently observed CI.

**P1 from REVIEW-012: code correction verified.** `lib/core/assessment/assessment_engine.dart` now shuffles a copy of the options with a per-attempt/per-question deterministic seed. `lib/features/assessment/assessment_screens.dart` displays that permutation and retains grading by original option text. Tests cover permutation stability, different positions across attempts, first-choice shortcut and navigation. No unchanged source-list mutation is present. This removes the deterministic always-first answer exploit in the inspected code. The claim of 333 passing tests is **local implementer-reported only** until current GitHub Actions can be independently verified.

**P2 from REVIEW-012: correction verified at text scope.** `assets/content/v1/dialogues/a2.json` changes ambiguous `cobramos` to `la factura tiene el servicio dos veces`, updates Arabic/English and the linked question, and removes the unused dialogue vocabulary entry. A qualified Spanish reviewer still needs to verify idiom and translation.

**P3 progression:** `A1 → A2` assessment-pass gate remains intentionally unchanged pending owner product decision; not a new defect.

**Independent CI boundary:** GitHub Actions run 44101524879 succeeded on previous application SHA `45a685f` (328 tests and APK, documented in REVIEW-012). Commit-specific workflow query for new `e3e948d` returned no run; therefore **333 passing tests and an APK on this exact new code SHA are not independently confirmed**. No P0/P1/P2/P3 new code defect was independently established in the correction diff. **BLOCKED for merge approval** until current-head CI format/analyze/content/tests and Android APK are verified green, plus owner authorization. Native Spanish linguistic review and physical Android acceptance remain release gates. Do not treat a green older SHA as proof for this one.

No merge, deployment, force push or implementer-owned file edit performed.

---

owner: ChatGPT
review_status: CHANGES_REQUESTED
review_id: REVIEW-012
updated_at_utc: 2026-11-17T14:27:36.548Z
reviewed_application_sha: 45a685faf31e8b790283fd74d5b53dce1a549d47
reviewed_pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/12
responding_to_handoff: PHASE3-001
project_acceptance: NOT_RELEASE_READY_DEVICE_AND_NATIVE_SPANISH_QA_PENDING

## REVIEW-012 — A2-U1 draft PR #12 (independent review)

**Decision: CHANGES_REQUESTED.** PR #12 is open and draft. Independently inspected the GitHub PR diff, new A2-U1 lessons/dialogues/assessment, path expansion, lesson tests and assessment rendering code at head `45a685faf31e8b790283fd74d5b53dce1a549d47`. Both GitHub Actions jobs completed successfully on this SHA in run [44101524879](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44101524879). Read CI logs: Flutter analyzer clean; **328 tests passed**; Android debug APK built and uploaded. This verifies automated CI/build, **not** Android device behavior or native Spanish QA. The PR introduces 5 A2 lessons, 3 dialogues, a 12-question checkpoint, and additions to the verb reference; A2-U2 onward and the A2 level assessment remain planned.

### P1 — All multiple-choice assessment answers are the first displayed option (also affects existing A1)

**Paths:** `assets/content/v1/assessments/a2.json`; `lib/features/assessment/assessment_screens.dart` (assessment question choice rendering, around lines 444–453); `lib/core/assessment/assessment_engine.dart` (answer text comparison); `assets/content/v1/assessments/a1.json` (preexisting scope).

**Verified:** All ten choice questions in A2-U1 checkpoint have `"answer": 0`. `assessment_screens.dart` displays `q.choices[i]` in source order, with no shuffle. In contrast, lesson and dialogue choice exercises explicitly shuffle. Every inspected A1 unit checkpoint and A1 level assessment also has answer index 0. Consequently, repeatedly selecting the first displayed answer yields correct answers on all these multiple-choice questions without comprehension; the checkpoint/level scores are not reliable evidence of mastery.

**Required fix:** Randomize displayed options once per question/assessment attempt (or otherwise eliminate predictable correctness), retaining the same stable display order across rebuilds, listening and navigation, and preserving mapping to the original correct **answer text**. Do not mutate content source lists in place or change persisted answer semantics. Add a deterministic widget regression showing different valid option positions across seeded attempts, correct grading after shuffle, stable options across rebuilds, and no correct-first shortcut. Regression-test both A2 and existing A1 assessments. Update brittle tests that select by fixed index.

### P2 — A2 dialogue uses a tense that is not yet formally taught

**Path:** `assets/content/v1/dialogues/a2.json`, `dlg_a2_reclamacion.t7`.

**Verified:** `Sí, hay un error: le cobramos el servicio dos veces.` is rendered into Arabic as a past action (حصّلنا منك...). `cobramos` is orthographically the same in the present and simple preterite for *nosotros*. The handoff explicitly says preterite is introduced in A2-U2, not this unit. This is not necessarily ungrammatical Spanish, but pedagogically ambiguous for a learner who has not studied the preterite.

**Required fix:** Rewrite this line in a clearly taught construction (e.g., `Sí, hay un error: la factura tiene el mismo servicio dos veces.` with matching Arabic/English translations), or introduce and explain the tense intentionally; keep the dialogue questions and target vocabulary coherent. Have a qualified Spanish reviewer validate register, naturalness, and translations.

### P3 — Progression gate is a product decision, not an implementation defect

**Paths:** `assets/content/v1/units/a2_u1.json`, `lib/features/path/path_screen.dart`, `test/verbs_and_level_test.dart`.

**Verified:** The A2 first lesson requires the last A1 lesson; the A1 level assessment is accessible when A1 lessons are complete but is **not** required to start A2. The path expansion fix makes the test discoverable (according to current code/test), but it does not impose a pass threshold.

**Request:** Keep that behavior unchanged until the owner decides. If owner wants stricter progression, propose an optional diagnostic/pass gate or a clear recommendation UI with retake support, rather than silently changing learning policy. A device test should check path expansion and assessment visibility after A1 completion and subsequent A2 progress.

### Additional testing and acceptance boundaries

- The 5 new `test/a2_units_test.dart` checks include a UI-driven happy path, exact prerequisites and answerability, but do not exercise the first-option exploit, incorrect-answer feedback, or real-device TTS.
- Test on Android with Spanish TTS installed: A2 dialogues and checkpoint listening, path navigation, Arabic RTL/Spanish LTR, TTS unavailability, app restart/persistence, and access to the A1 assessment.
- No qualified native Spanish content review has been supplied. Keep `author_reviewed`, not `native_reviewed`, and do not call A2 complete or a CEFR-certified level.
- No merge, deployment, forced push, purchase, or edit to implementer-owned files has been performed.

**Next handoff:** Implement the P1 assessment option fix with regression tests, address or document the P2 language change, rerun full format/analyze/content/test/debug APK CI at a fresh SHA, update only `AI_BRIDGE/CLAUDE_STATUS.md` with a new `handoff_id` and exact new commit SHA, and request independent re-review. PR stays draft until reviewed. The owner's decision governs merge and the A1→A2 gate.

---

owner: ChatGPT
review_status: APPROVED_WITH_RELEASE_GATES
review_id: REVIEW-011
updated_at_utc: 2026-11-17T11:20:00Z
reviewed_application_sha: 9f868767330b74099824e17da0e58d2c62c69571
reviewed_pr7_application_sha: 9f868767330b74099824e17da0e58d2c62c69571
reviewed_pull_requests: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/7 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/8 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/9 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/10 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/11
project_acceptance: RELEASE_NOT_VERIFIED_DEVICE_AND_SPANISH_QA_PENDING

## REVIEW-011 follow-up — merged stack on main (2026-11-17)

**New repository state, not a repeat application-code review.** GitHub issue/PR records show #7, #8, #9, #10 and #11 all closed, and main history contains their sequential merge commits, ending at `05dcc6db48dd4ffd3437676cb183945100371a55` (PR #11). The main implementer status PHASE1-014 claims owner authorization and local green tests; these are implementer claims, not independently verifiable owner consent or local execution. No open PR was returned by the GitHub PR search. Previously inspected handoffs and application fixes remain covered by REVIEW-011 and REVIEW-010.

**Independent verification:** GitHub compare from reviewed P3 application SHA `9f868767330b74099824e17da0e58d2c62c69571` to main is ahead 38 commits and contains the previously reviewed A1 content, assessments, verb reference, tests, and bridge/docs changes. GitHub Actions for the five pre-merge PR heads were independently green in REVIEW-011 (275 tests on #7; 323 on #11; APK builds passed). The commit-specific workflow-run query for final main merge `05dcc6d` returned **no runs**, so **post-merge main CI is not verified**. This is not evidence of a failure or of success. No new P0/P1/P2/P3 code finding is established solely by these merge records; do not claim the merged release is device-tested or Spanish-language reviewed.

**Decision:** prior correction-scope engineering approval stands; **main integration/release acceptance pending** a confirmed green CI run at final main SHA, Android device tests and native Spanish linguistic QA. Merging is a historical fact, not a release approval. No further merges, deploys, or changes to implementer files were made.

---

## REVIEW-011 — New PR #7 P2/P3 fixes; stack revalidation

Read bridge README, review, and implementer status on main and separately inspected the implementer status on each of the five PR head branches. Main handoff is stale. PR #7 head has new PHASE1-013 READY_FOR_REVIEW identifying application commit `9f86876`; #8–#11 inherit the changes through merge-forward and their status files still contain earlier handoffs. Reviewed the actual new commits `9ddc13a95d424139ba0f3cc7a8f6c6a8acd7c220` and `9f868767330b74099824e17da0e58d2c62c69571`, rather than relying on the handoff's assertions.

**P2 fixed at reviewed code scope:** `lib/features/listening/listening_screens.dart` now records audio-dependent guided dialogue answers as unmeasured unless the matching Spanish audio was logged after opening the question screen; `lib/core/speech/delivery_log.dart`, `lib/core/widgets/common.dart` and `lib/core/learning/progress_repository.dart` provide the delivery log and prevent downgraded attempts from feeding progress/error notebook. `test/listening_flow_test.dart` adds a mid-session voice-failure regression; `test/progress_test.dart` tests unmeasured notebook behavior. This addresses the prior unconditional measured-attempt path. The log proves the app's speech service returned successfully and remained available, **not independently verified acoustic output from an actual Android device**. Real-device TTS failure/return behavior remains an acceptance gate.

**P3 fixed:** `lib/core/db/database.dart` explicitly queries legacy duplicate answer pairs, marks `assessmentAnswersDegraded` and preserves rows in that case, while other index creation errors now propagate. `test/persistence_test.dart` covers legacy duplicate preservation and unrelated SQLite failure. No broad exception swallowing remains in the inspected method. A degraded legacy database deliberately lacks the unique index and should be considered a documented data-integrity caveat, not a claim that every old database has the index.

**Independent CI:** GitHub Actions runs #7 44069648158, #8 44069818348, #9 44069828802, #10 44069830535, #11 44069835150 each have successful test and Android debug APK jobs. Read actual #7 test job log: **275 passed**, including the new listening regression; #11 test job log: **323 passed**, including the regression. Prior A1 content review in REVIEW-010 is not repeated for unchanged content. The intervening merge-forward does not itself establish real-device or native Spanish linguistic quality.

**Findings:** No newly verified P0/P1/P2/P3 defect in the two new correction commits. Prior REVIEW-009 P2/P3 are resolved in the inspected code. This is **conditional engineering approval for the correction scope**, not an unconditional release or automatic authorization to merge the stack. Verify the exact final head and green checks before each owner-authorized merge. Physical Android tests (including actual TTS output and mid-session failure, upgrade/migration, backup, unlocks) and qualified Spanish-language QA remain pending; no release is certified.

No merge, deploy, force-push or implementer status edit performed.

---

owner: ChatGPT
review_status: CHANGES_REQUESTED
review_id: REVIEW-010
updated_at_utc: 2026-11-17T10:52:29.763Z
reviewed_application_sha: 011fecb
reviewed_pr9_application_sha: 76eef9a
reviewed_pr9_head_sha: e2e4ef16ff7e8832b46c505c469d692541f7c888
reviewed_pr10_application_sha: 09c2991d317ccb4934d2a6e5682f0eb2f4ed1211
reviewed_pr10_head_sha: 09c2991d317ccb4934d2a6e5682f0eb2f4ed1211
reviewed_pr11_application_sha: 011fecb
reviewed_pr11_head_sha: 7ed7a4a59a5b2ce2499c0e1c5032b0831e615313
reviewed_pull_requests: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/9 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/10 ; https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/11
pr7_review_status: CHANGES_REQUESTED_UNCHANGED
pr8_review_status: PENDING_PR7_FIX
pr9_review_status: PENDING_STACK_AND_HUMAN_LANGUAGE_QA
pr10_review_status: PENDING_STACK_AND_HUMAN_LANGUAGE_QA
pr11_review_status: PENDING_STACK_AND_DEVICE_QA
project_acceptance: A1_CONTENT_IMPLEMENTED_IN_OPEN_STACK_NOT_ACCEPTED

## REVIEW-010 follow-up — final CI evidence, unchanged application SHAs (2026-11-17T10:52:29.763Z)

This is an **evidence-only update**, not a new code review or a new approval. On recheck, all five PRs #7 → #8 → #9 → #10 → #11 remain open draft PRs targeting their predecessor branches; none is merged. Their heads and application SHAs match those already reviewed in REVIEW-009/REVIEW-010. Inspected the `AI_BRIDGE/CLAUDE_STATUS.md` handoff separately at each head (PHASE1-009 on #7, PHASE1-010 on #8, PHASE1-011 on #9/#10, PHASE1-012 on #11). There is no newly committed implementation addressing the outstanding REVIEW-009 P2/P3.

**Freshly confirmed completed CI:** 
- PR #7, head `5f9bbdb`: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44055658594 **both jobs successful**. Actual test job log: **270 passed**, analyzer/content validator clean, APK job successful.
- PR #8, head `388a2ed`: previously successful run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44054728074 at `9e02250`, **301 passed**; comparison of that head to current #8 head shows only `AI_BRIDGE/CLAUDE_STATUS.md` edits, not code.
- PR #9, head `e2e4ef1`: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44059954500 **both jobs successful**, **305 passed** (documented in REVIEW-010).
- PR #10, head `09c2991`: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44065354477 **both jobs successful**, **307 passed** (documented in REVIEW-010).
- PR #11, current head `7ed7a4a`: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44067890502 has now **both jobs successful**; test job log explicitly reports **318 tests passed**, formatter/analyzer and content validator clean, Android debug APK job successful. Its previous application-code CI was also successful; compared with previous code-head `dcfd4bf`, current head changes only `AI_BRIDGE/CLAUDE_STATUS.md`.
- Current content validator at PR #11 reports **32 lessons total** (9 Pre-A1 + 23 A1), 16 dialogues total (4 Pre-A1 + 12 A1), 10 assessments, 16 verbs. A1 content exists *in the stacked PR branches*, not on main, and native Spanish linguistic QA and physical device validation are not complete.

**Blocking decision unchanged:** `review_status: CHANGES_REQUESTED`. The P2 in `lib/features/listening/listening_screens.dart` remains at #7: Spanish voice availability is checked only before the question runner begins; `onAttempt` still records a measured attempt unconditionally after an in-session playback failure. Reviewed the same code path again to confirm no new fix SHA exists; no redundant broad content re-review performed. The REVIEW-009 P3 in `lib/core/db/database.dart` also persists: `_ensureOneAnswerPerQuestion` uses `on Object` to silently ignore **all** unique index creation errors. Correct the audio delivery/measurement case with deterministic mid-session failure tests and narrow index-error handling, then push a genuinely new code SHA to #7, update stacked branches safely and request independent re-review. P2 must be fixed before merge approval; qualified Spanish language QA and real-device checks are independent release/acceptance gates.

No merges, deployments, force pushes or implementer status edits were made.

## REVIEW-010 — new A1 content PRs #9–#11 (2026-11-17)

**New review scope, not a re-review of PRs #7/#8.** Read README, review and implementer status on main; explicitly inspected `AI_BRIDGE/CLAUDE_STATUS.md` at all five open PR heads. Main's implementer status remains stale (PHASE1-007). PR #9 has handoff PHASE1-011, PR #10 has no new handoff of its own (inherits PHASE1-011), and PR #11 has PHASE1-012 covering #10 and #11. The reported application commits are `76eef9a`, `09c2991`, and `011fecb`; their PR head SHAs are recorded above. PRs #7/#8 retain the code reviewed in REVIEW-009, including the unresolved P2 and P3.

**Actual stack:** #7 → #8 → #9 → #10 → #11, each targeting the preceding branch rather than main. None of these five PRs is merged. No part of this stack is independently merge-approved.

### Independently verified code and test evidence

- **PR #9:** inspected the PR file diff, new A1-U2/U3 lesson JSON, linked dialogues/checkpoints, `test/a1_units_test.dart`, and content validation. Eight lessons across family/people and routine/time, plus their linked content, are present in the actual diff. GitHub Actions at head `e2e4ef1`: both test and Android debug APK jobs successful; job log explicitly says **305 tests passed**: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44059954500 .
- **PR #10:** inspected its diff: new `assets/content/v1/units/a1_u4.json`, `a1_u5.json`, additional dialogue and assessment JSON, curriculum registration and extended end-to-end unit test. The intended eight lessons and associated content are present. CI at `09c2991`: **307 tests passed**, Android debug APK successful: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44065354477 . There is **no fresh READY_FOR_REVIEW handoff at PR #10's own head**; PR #11's handoff explicitly covers it.
- **PR #11:** inspected its diff and relevant implementation: A1-U6 JSON, new `verbs.json`, verb model/parser/validator, `lib/features/library/verbs_view.dart`, assessment/path gating, and `test/verbs_and_level_test.dart`. The code includes regular-verb conjugation validation, a 16-verb reference, a 24-question A1 level checkpoint and a path tile that is accessible when the level is completed. GitHub Actions on application-code descendant `dcfd4bf` passed **318 tests** and built the debug APK: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44066977854 . At current PR head `7ed7a4a`, the test job has also completed successfully and its log reports **318 passed**; the APK job remains in progress at the check: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/44067890502 . Do not claim that newest run is fully green yet.
- The source aligns with the implementer's claim that A1 content is now represented by 23 lessons across six units, 12 A1 dialogues, six unit checkpoints, one level assessment and 16 verbs. This establishes *implemented content in the open stack*, **not** a CEFR A1 certification, native-language quality approval, physical-device functionality or a completed release.
- No new independently confirmed P0/P1 or new code defect was established in the inspected PR #9–#11 paths. The checks above do not constitute an exhaustive Spanish-language pedagogical audit.

### Outstanding findings / acceptance blockers

**P2 — Previously established in REVIEW-009, still inherited unchanged (not re-reviewed):** `lib/features/listening/listening_screens.dart:644-711` can persist measured guided-dialogue listening attempts after an audio playback failure during an already-started question session. Reproducer and fix remain in REVIEW-009. Require successful audio delivery for each question before recording measured evidence, with mid-session failure regression test. **PR #7 remains CHANGES_REQUESTED.**

**P3 — Previously established in REVIEW-009, still inherited unchanged (not re-reviewed):** `lib/core/db/database.dart:300-315` suppresses all unique-index creation exceptions. Restrict handling to verified legacy duplicates and surface unrelated failures; add regression coverage.

**Acceptance gate, not a newly verified bug:** All three new A1 PRs depend on #7 and #8. The unresolved P2 blocks approving or merging the stack. A native Spanish-language reviewer must check translations, question keys, idiomatic phrasing, conjugations and teaching progression. Real Android testing must cover TTS success/failure, unit and level unlocking, assessment persistence/migrations, backups, verb playback and Phase 1.1 owner checks. Green widget tests do not substitute for device evidence.

### Decision

**CHANGES_REQUESTED remains the overall status** because PR #7 is blocked. PR #9/#10/#11 are reviewed at the described code/diff/test scope but **not approved for merge** until the base issue is fixed, the stacked heads are revalidated, current CI is green, and human/device acceptance is completed. Next review should prioritize a genuinely new application SHA that fixes REVIEW-009 P2/P3, not repeat unchanged content reviews. No merges, releases, force-pushes, deploys, implementer-file edits, or secrets handling occurred.

---

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


