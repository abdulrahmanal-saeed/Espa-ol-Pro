# ChatGPT → Claude Code: Independent Engineering Review

owner: ChatGPT
review_status: APPROVED
review_id: REVIEW-004
updated_at_utc: 2026-11-16T17:54:50.088Z
reviewed_commit_sha: ef35c1ee3a8944a9a4d1d4f7191648ff9a58051e
reviewed_application_sha: 65324da6e0e2b6d110ca8b550ce4e761096241ec
reviewed_followup_test_sha: b0c1b9aba99a3648ebe49d29cdb958926eb9f343
reviewed_pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/2
project_acceptance: PHASE_1_CORE_DEVICE_CHECKS_OWNER_CONFIRMED_LINGUISTIC_VALIDATION_PENDING

## Owner-reported device QA addendum (2026-11-16)

**The project owner explicitly confirmed testing the following with Codex on a real device and reported all working:** (1) reviews and progress after closing/reopening the app, (2) backup export and restore, (3) learning without an internet connection, (4) Spanish audio playback, and (5) on-screen keyboard interaction. This is **firsthand owner acceptance evidence**, not a test independently witnessed or reproduced by ChatGPT. The previous "remaining physical Android acceptance matrix" below is superseded for these five flows. Do not ask the owner to repeat them without new evidence of regression.

Still not covered by this confirmation: every accent/voice/speed variant; all wrong-answer recovery cases on device; every Settings/theme accessibility case; first A1 transition on-device after completing all Pre-A1; and an independent Spanish language/etymology content review. Automated tests cover some of these paths, but this addendum does not claim manual device proof for them.

The latest inspected application SHA is unchanged, so this is an evidence update to REVIEW-004 rather than a new code review or REVIEW-005. Future changes still require a new handoff and code review.

## Verdict — engineering fixes approved, not the entire product

**All previously identified P0/P1 engineering blockers from REVIEW-001 through REVIEW-003 are resolved in the merged code as far as source review and CI can establish.** PR #2 is already merged into `main` at `ef35c1e`. The merge commit has successful CI (verification and Android debug APK build) and 105 passing tests. This is **not** a claim of completed Pre-A1→C2 product or full Phase 1 device/language acceptance. No new application implementation commits after `65324da` were found in the checked history. The new `b0c1b9` commit added an A1 unlock regression test and updated documentation.

Review evidence:
- Merge: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/commit/ef35c1ee3a8944a9a4d1d4f7191648ff9a58051e
- Green merge CI: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43918437105
- Green final PR CI: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43909415732
- Final CI log explicitly reports `105 tests passed`, `No issues found!`, successful content v1.0.2 validation with 12 lessons, 101 vocabulary items, 299 activities (172 graded), 14 grammar notes, and successfully uploaded Android debug APK.
- Source has previously been reviewed for restore validation, FSRS due-time checks, transactionally persisted review ratings and study time, retryable failed answer saves, v3 migration and first-try analytics. No independent local rerun or fresh install by this reviewer was done in this turn.

## Confirmed closure of previous blocking findings

1. **P1 backup loss:** Missing/malformed/inconsistent backup data is validated before destructive restore, with negative tests comparing full data snapshots; newer fields are schema-aware.
2. **P1 FSRS premature reviews:** Future-due cards remain locked until the due instant, with clock-controlled widget tests.
3. **P1 Android build:** The NDK setup is now repeatable; both final PR and merged main Android debug APK builds passed.
4. **P1 answer-save failure path:** A failed SQLite write leaves the submission pending without scoring/advancing; recovery is covered by widget tests.
5. **P2 coached retries inflating skill statistics:** Version 3 records `attempt_number`; skill evidence excludes retries.
6. **P2 review rating and study checkpoints:** Written together transactionally, with rollback/reopen tests. Unrated partial card time is still not captured.

## New follow-up evidence

- `test/app_flow_test.dart` adds a widget test verifying the first A1 lesson stays locked until the complete Pre-A1 sequence is completed, then becomes startable.
- `docs/REVIEW_HANDOFF.md` and `docs/IMPLEMENTATION_STATUS.md` document a **reported** Android runtime check: the debug APK installed and launched on a Samsung Galaxy A15 (Android 16); learner reportedly completed the first Pre-A1 lesson, with SQLite entries for 11 graded attempts and 14 FSRS cards. This report is more concrete than the previous no-device-run status, but it is **documentation by the implementer/owner**, not a separately witnessed device test by this reviewer.
- The same docs report unsuccessful API 36 emulator attempts due to Android process/System UI timeouts. This does not establish a failure in the Flutter app; retest on a stable emulator or physical device if needed.

## Remaining follow-ups (not a reversal of engineering approval)

### P2 — Owner completed the five previously reported device smoke-test flows

- The owner has now directly confirmed that review persistence after closing the app, backup export/restore, offline operation, audio, and keyboard **work on-device** during testing with Codex. This clears those five previously outstanding smoke-test items on owner testimony.
- Remaining optional/deeper manual checks are not covered by that statement (full audio variant matrix, accent-specific input, every theme/setting, A1 transition on device). Ask implementer to update their own device-evidence docs and note actual test device/build, without exposing personal data.
- The core engineering foundation and these smoke tests are acceptable to continue development. Qualified Spanish content validation remains a separate gate; do not misrepresent the full Pre-A1→C2 roadmap as finished.

### P2 — Communication bridge and current docs are stale on main

- `AI_BRIDGE/CLAUDE_STATUS.md` on `main` still claims PR #2 is draft/unmerged and refers to `PHASE1-002` / `25e9ac3`, despite merge `ef35c1e`. `AI_BRIDGE/PROJECT_PLAN.md` and the start of `docs/IMPLEMENTATION_STATUS.md` also contain outdated pre-merge descriptions.
- Claude/Codex should update **only Claude-owned `AI_BRIDGE/CLAUDE_STATUS.md`**, `AI_BRIDGE/PROJECT_PLAN.md`, and their own implementation docs to accurately reflect merge and latest review, using a new handoff ID (`PHASE1-003`) for the **next** new code milestone. Never overwrite this ChatGPT-owned review file.
- Review automation should inspect PR head SHAs as well as main so the stale pointer does not mask new work.

### P2 — Review duration edge case

- Review-study time is stored on successfully rated cards. Time spent on an opened, unrated card is not currently checkpointed when user exits. Decide whether to document as limitation or add safe app-lifecycle checkpoints before calling study time comprehensive.

### P3 — Spanish content still needs educational QA

- Curriculum text has only author/machine review. Obtain a qualified Spanish-speaker review for all 12 lessons, audio quality, pronunciation claims, translations and etymology (especially `hasta` and `cero`). Verify references rather than presenting unverified etymologies as certain.

### P3 — Deferred product functionality is not a bug in this milestone

- No AI tutor/roleplay, audio recording/STT, formal CEFR testing, complete A1–C2 content, or advanced professional missions yet. These belong to subsequent phases and must remain visibly incomplete.
- The app icon/splash and optional convenience features also remain pending.

## Next steps

1. Keep merged Phase 1 engineering fixes as provisionally approved; do not rewrite, revert, or force-push them.
2. Treat owner-confirmed offline, audio, keyboard, backup/restore, and review-after-relaunch flows as completed smoke tests; request Codex to update its device-evidence documentation. Schedule only genuinely uncovered deeper device tests when useful.
3. Correct Claude-owned bridge status and outdated PR draft references without editing `CHATGPT_REVIEW.md`.
4. Continue agreed Phase 1.1 and beyond as separate reviewable commits/PRs. Include actual head SHA, test/CI evidence, and handoff to reviewer.
5. **Do not treat this engineering approval as owner confirmation of completed Phase 1 or completed Español Pro.** Project monitoring remains active.

Scope of this REVIEW-004: new A1 unlock test and documentation commit after REVIEW-003, merged final code state, and CI completion. No repeat re-review of unchanged application SHA.
