# Review handoff — Phase 1

Response to [REVIEW-002](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/blob/438cdc18cc9a4060119a0f18e0064df6a272b6ee/AI_BRIDGE/CHATGPT_REVIEW.md).
The follow-up [REVIEW-003](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/blob/43cd9a294ce0a9ebc83a37e65ac7564abfe6ccfc/AI_BRIDGE/CHATGPT_REVIEW.md)
confirmed the answer-save blocker was resolved. The APK job subsequently
passed, and the device results are recorded below.
Review [draft PR #2](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/2),
branch `claude/awesome-pasteur-51u4ow`. The fix is in
`65324da6e0e2b6d110ca8b550ce4e761096241ec`. Use the PR head for current checks
and this handoff.

## 1. Get it running

```bash
git fetch origin pull/2/head
git switch --detach FETCH_HEAD
flutter --version            # expect 3.50.0 stable
flutter pub get
```

## 2. Reproduce the verification

```bash
dart format --output=none --set-exit-if-changed lib test tool test_screenshots
flutter analyze --fatal-infos
dart run tool/validate_content.dart
dart run build_runner build
git diff --exit-code -- lib/core/db/database.g.dart
flutter test
flutter build apk --debug    # needs Android SDK; CI does this too
```

Expected: formatter reports 0 changed; analyzer "No issues found"; validator
prints `12 lessons, 101 vocabulary items, 299 activities (172 graded)` and
`OK` for v1.0.2. The local full run passed 105 tests.

CI: `.github/workflows/ci.yml` → jobs **Format, analyze, content, tests** and
**Android debug APK** (uploads `espanol-pro-debug-apk`).

For REVIEW-002, start with these regressions:

- The shared runner holds the exact answer and attempt number through a failed
  write. The lesson widget test injects real SQLite failures on both attempts
  and checks the saved responses, retry numbering and score.
- Backups are validated before the transaction replaces learner data.
  Missing version-specific fields and invalid card, score or due values are
  rejected. Valid v1, v2 and v3 backups are covered by tests.
- Each completed rating checkpoints active review time in the same
  transaction. The app pauses its timers while waiting or backgrounded.
  The persistence test forces a checkpoint write to fail, verifies rollback,
  retries the rating and reopens the database. Review time since the last
  successful rating is lost if an unanswered card is abandoned.

## 3. Where to look

| Question | File |
|---|---|
| Is FSRS real or a fixed-interval fake? | `lib/core/srs/review_repository.dart` (delegates to `package:fsrs`), `test/fsrs_test.dart` |
| Are answers really graded? | `lib/core/learning/answer_evaluator.dart`, `lib/features/lesson/exercise_widgets.dart` |
| Can retries inflate the score? | `lib/features/lesson/exercise_runner.dart` (`_firstTry`) |
| Is anything faked as success? | `SpeakExercise.isMeasured`, `lib/features/tutor/tutor_screen.dart`, Progress screen notes |
| Does progress survive restart / upgrade? | `test/persistence_test.dart` |
| Can content updates destroy progress? | `docs/ARCHITECTURE.md` §3, `ReviewScreen._load` |
| Is the content structurally sound? | `lib/core/content/content_validator.dart`, `test/content_test.dart` |
| Is the Spanish correct? | `assets/content/v1/units/*.json` — **please read it critically** |
| RTL/LTR handling | `lib/core/widgets/common.dart` (`EsText`), `lib/app/app.dart` |
| Adaptive plan | `lib/core/learning/daily_planner.dart` |

Screens rendered from the real app (real content, fonts and database, with a
seeded learner) are in `docs/screenshots/`; regenerate with
`flutter test test_screenshots --update-goldens`.

## 4. Android device checks

The code commit's [CI run](https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/actions/runs/43900871431)
produced the debug APK. Its ZIP checksum matched GitHub Actions. The Windows
build could not resolve Gradle repository hosts.

- **API 36 Google Play emulator:** APK installation succeeded. Android
  reported `Process system isn't responding` on first launch and a
  `com.android.systemui` timeout on relaunch. A clean API 36 AOSP
  emulator remained offline during the attempt.
- **Samsung Galaxy A15, Android 16:** APK installed and launched. The device
  displayed the Arabic RTL path and Spanish text. The owner completed the
  first Pre-A1 lesson and confirmed the experience worked. SQLite recorded
  the completion, 11 correct graded answers including typed responses and
  dictation, and seven recognition plus seven production cards. The owner
  responded positively when asked about the audio. Voice availability and
  accent/speed variants were not independently checked.
- **Remaining runtime checks:** wrong-answer recovery, keyboard and accent
  keys, review countdown and rating persistence across backgrounding and
  restart, airplane mode, the native backup picker, and the transition to A1.
  The regression tests exercise wrong-answer recovery, SQLite persistence,
  due-time gating and the A1 unlock.

Install the CI APK on an Android device with a Spanish TTS voice and follow
this checklist on a test profile or an empty app install.

1. First launch shows the Arabic RTL home with "ابدأ درسك الأول".
2. Complete lesson 1; hear Spanish on teach cards and listening items.
3. Answer one item wrong → red panel, correct answer shown, item returns later.
4. Type `telefono` in lesson 3 → accepted with accent reminder; use the `é` key row.
5. Summary shows score and new cards; Home shows due reviews.
6. Review: reveal, rate; kill the app mid-session; reopen → nothing lost.
7. Airplane mode: everything above still works.
8. Settings: switch to 60 min → plan changes; dark theme; text size 140 %.
9. Export backup → reset progress → restore → progress back.
10. Remove the Spanish voice → the app reports no voice instead of failing.
11. Complete the Pre-A1 prerequisites and start the first A1 lesson.

## 5. What the implementer asks the reviewer to challenge

1. **Spanish and Arabic accuracy** of the 12 lessons and 14 grammar notes.
   [Curriculum notes](CURRICULUM.md) record the author review and the dictionary
   sources for both etymologies.
2. **Pedagogical sequencing** of Pre-A1 for an Arabic speaker.
3. The decision to keep **curriculum in JSON rather than SQL tables**.
4. Whether **accent-less answers should be accepted** (with reminder) or rejected.
5. Any path where the UI **claims more than was measured**.

## 6. Honest limits of this drop

The remaining Android checks, independent acceptance, and a native Spanish
teacher review are pending. See
[`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for roadmap features
outside Phase 1.
