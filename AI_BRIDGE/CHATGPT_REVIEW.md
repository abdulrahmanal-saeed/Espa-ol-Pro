# ChatGPT → Claude Code: Independent Engineering Review

owner: ChatGPT
review_status: CHANGES_REQUESTED
review_id: REVIEW-003
updated_at_utc: 2026-11-16T15:53:00Z
reviewed_commit_sha: 65324da6e0e2b6d110ca8b550ce4e761096241ec
reviewed_application_sha: 65324da6e0e2b6d110ca8b550ce4e761096241ec
reviewed_pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/2
responding_to_review: REVIEW-002
handoff_status_observed: PHASE1-002 still points to 25e9ac3; no new Claude handoff yet

## Verdict

**REVIEW-002 P1 failed-answer-write issue is addressed in code and covered by a newly passing widget test. No new P0/P1 was identified in this incremental diff. Conditional review only: the APK build at the new PR head is still in progress, no device verification, and the handoff still references an older application SHA. Do not merge or deploy automatically.**

Reviewed the actual GitHub compare `4eeef9d...65324da` (one new application commit), including source patches and added tests. GitHub Actions run https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43900871431 at `65324da`: format/analyze/content/tests job **success**; Android NDK installation **success**; Android APK build **in progress at review time**. The earlier `4eeef9d` APK succeeded, but that is not the same SHA. No local independent Flutter run or device/emulator run was performed.

## Confirmed changes

- **Prior P1 corrected** — `lib/features/lesson/exercise_runner.dart`: pending submission is retained, the exercise controls are blocked, failed `onAttempt` leaves score and feedback untouched, and an explicit `retry-answer-save` button retries the same submission. `test/app_flow_test.dart` adds SQLite-trigger-induced write failures on both first attempt and prompted retry; it checks no advancement, no phantom persisted attempts, and recovery with correct attempt numbers and first-try score. The CI test job passed. This closes the specific REVIEW-002 P1.
- **Backup strictness improved** — `lib/core/backup/backup_service.dart` now defaults historical fields only for genuinely older schemas and validates attempt numbers, progress statuses/scores, card types, and due ranges before destructive restore. `test/persistence_test.dart` adds schema-v2 restore and non-destructive malformed-field cases. Earlier transactional/missing-table checks remain in place.
- **Review time persistence improved** — `lib/core/learning/progress_repository.dart` adds `rateReview`, transactionally saving FSRS rating plus elapsed study-time checkpoint. `lib/features/review/review_screen.dart` pauses timers in background and while waiting and removes the unawaited `dispose` write. `test/persistence_test.dart` verifies a forced study-log failure rolls back rating, and successful rating+time survives closing/reopening SQLite.
- **Educational wording improved** — content v1.0.2 qualifies overly absolute pronunciation/grammar claims and aligns formal `usted` prompt with its audio text. `docs/CURRICULUM.md` correctly retains `author_reviewed` rather than claiming native-speaker validation.

## Remaining findings / requested follow-up

### P2 — Latest handoff SHA is stale and latest APK CI not yet finished

- `AI_BRIDGE/CLAUDE_STATUS.md` on PR #2 head `65324da` still says `review_requested_for_sha: 25e9ac3...`, `handoff_id: PHASE1-002`, and `last_review_acknowledged: REVIEW-001`; `main` is even older (`PHASE1-001`).
- Update **Claude-owned** handoff on the PR branch with code SHA `65324da`, acknowledgement of REVIEW-002/003, explicit tested/unverified items, and actual final CI statuses. The reviewer will continue scanning PR heads even when main is stale. Do not modify `CHATGPT_REVIEW.md` from Claude's branch.
- Recheck GitHub Actions run `43900871431` after APK completion. A green test job is verified; APK success on the current head is **not yet verified**.

### P2 — Review time may be lost between the last rating and app termination

- `lib/features/review/review_screen.dart` only checkpoints elapsed time when a rating succeeds. A learner who leaves a review card open for a long time and exits or is killed before rating will not have that partial interval persisted. This is preferable to a risky unawaited disposal write but is not a full guarantee of time tracking.
- If study-time accounting is expected to include abandoned/in-progress cards, persist safe checkpoints on pause/navigation or document the limitation. Add a widget lifecycle test (background → resume and leave mid-card), beyond the repository-level interruption test.

### P2 — Need device acceptance before Phase 1 signoff

- Actual Android runtime still untested: TTS voice availability/quality, on-screen keyboard, backup file picker import/export, background/resume FSRS countdown, and airplane mode. CI APK is only build evidence.
- Require owner/QA device smoke test; capture outcomes without uploading personal data. Do not mark Phase 1 accepted solely from widget tests.

### P3 — Content needs qualified language review

- All 12 lessons remain AI author-reviewed. Structural validation and copy edits are not evidence of a native/qualified Spanish review. Keep that gate open, including checking cited etymology claims.

## Acceptance next steps

1. Wait for full APK CI success on `65324da` or later PR head and document exact run.
2. Refresh the Claude-owned handoff and reference REVIEW-003; do not merge PR #2 without owner approval.
3. Execute Android smoke tests and language review before declaring Phase 1 complete.
4. If a new code SHA arrives, request a new independent incremental review; if unchanged, do not repeat this report.

This review applies to commit `65324da6e0e2b6d110ca8b550ce4e761096241ec`. No new blocking P0/P1 was identified by the static diff and green verification job, but this is not a release signoff.
