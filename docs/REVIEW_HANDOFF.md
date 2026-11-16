# Review handoff — Phase 1

For an independent engineer or AI reviewer. Exact branch / commit / PR for the
current drop: [`AI_BRIDGE/CLAUDE_STATUS.md`](../AI_BRIDGE/CLAUDE_STATUS.md).

## 1. Get it running

```bash
git fetch origin && git checkout <branch from CLAUDE_STATUS.md>
flutter --version            # expect 3.50.0 stable
flutter pub get
```

## 2. Reproduce the verification

```bash
dart format --output=none --set-exit-if-changed lib test tool test_screenshots
flutter analyze --fatal-infos
dart run tool/validate_content.dart
flutter test
flutter build apk --debug    # needs Android SDK; CI does this too
```

Expected: formatter reports 0 changed; analyzer "No issues found"; validator
prints `12 lessons, 101 vocabulary items, 299 activities (172 graded)` and
`OK`; `flutter test` reports 100 passing.

CI: `.github/workflows/ci.yml` → jobs **Format, analyze, content, tests** and
**Android debug APK** (uploads `espanol-pro-debug-apk`).

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

## 4. Manual device checklist (not yet performed by the implementer)

Install the CI APK on an Android phone with a Spanish TTS voice, then:

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

## 5. What the implementer asks the reviewer to challenge

1. **Spanish and Arabic accuracy** of the 12 lessons and 14 grammar notes,
   especially pronunciation descriptions and the two etymology claims
   (`hasta` ← حتّى, `cero` ← صِفْر).
2. **Pedagogical sequencing** of Pre-A1 for an Arabic speaker.
3. The decision to keep **curriculum in JSON rather than SQL tables**.
4. Whether **accent-less answers should be accepted** (with reminder) or rejected.
5. Any path where the UI **claims more than was measured**.

## 6. Honest limits of this drop

Not built or run on Android by the implementer (no SDK in the sandbox) — the
CI APK job is the only build evidence. Audio, file dialogs and keyboard
behaviour are unverified on hardware. No AI, no speech input, no assessments.
Content is not native-reviewed. Full list: `IMPLEMENTATION_STATUS.md`.
