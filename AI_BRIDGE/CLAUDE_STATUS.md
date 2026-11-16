# Claude Code → ChatGPT: Implementation Handoff

owner: Claude Code
handoff_status: IN_PROGRESS
handoff_id: PHASE1-003
updated_at_utc: 2026-11-17T09:00:00Z
review_requested_for_sha: none yet
branch: feat/phase-1.1-foundation
pull_request: not opened yet
last_review_acknowledged: REVIEW-004
project_status: PHASE_1_ENGINEERING_APPROVED__PHASE_1_1_IN_PROGRESS

## Acknowledgement of REVIEW-004

- PR #1 and PR #2 are merged into `main` (PR #2 merge `ef35c1e`). The
  previous version of this file still described PR #2 as an open draft and
  `PHASE1-002` / `25e9ac3` as current. That was stale and is corrected here.
- The REVIEW-002 findings were fixed by Codex in `65324da`; REVIEW-003 and
  REVIEW-004 verified them. I did not author those fixes and do not claim
  them.
- REVIEW-004 approved the Phase 1 engineering fixes. CI on the merge passed:
  105 tests, analysis, formatting, content validation, debug APK
  ([run 43918437105](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43918437105)).

## Owner-confirmed device checks

The owner tested these with Codex on a real Android device and reported all
working (recorded in the REVIEW-004 addendum):

1. Reviews and learning progress after closing and reopening the app.
2. Backup export and restore.
3. Offline operation.
4. Spanish audio playback.
5. On-screen keyboard input.

This is owner testimony, not automated or reviewer-witnessed evidence. I will
not ask for these to be repeated unless a change touches them or a
regression is reported. Not covered: every accent/voice/speed variant, every
Settings/theme case, the A1 transition on device.

## Remaining Phase 1 gate

Human review of the Spanish content (12 lessons, 14 grammar notes,
pronunciation claims, translations, and the `hasta` / `cero` etymologies).
Content stays `author_reviewed`. This does not block engineering work.

## Current work: Phase 1.1

Branch `feat/phase-1.1-foundation`, from `main` at `6f3ee26`. Planned as two
reviewable PRs:

- **PR A:** app identity (icon, adaptive icon, splash), saved phrases (schema
  v4), live review-due counter, review-time checkpoint for an unrated card
  (REVIEW-004 P2), and these documentation corrections.
- **PR B:** local study reminders (native notification plugin, permission
  handling, time zones). Kept separate because it adds native dependencies.

This file will be set to `READY_FOR_REVIEW` with the exact code SHA, PR URL
and CI results when PR A is pushed.
