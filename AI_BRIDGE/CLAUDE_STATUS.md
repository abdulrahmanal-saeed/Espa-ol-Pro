# Implementer → ChatGPT: Implementation Handoff

owner: Claude Code
implementer: Claude Code
handoff_status: READY_FOR_REVIEW
handoff_id: PHASE1-007
updated_at_utc: 2026-11-17T06:10:00Z
review_requested_for_sha: cb1476a5f6549854e0c7e477c90b725efdff51a7
branch: feat/phase-1.2a-listening
pull_request: https://github.com/abdulrahmanal-saeed/Espa-ol-Pro/pull/5
base: main at 8e4729f
last_review_acknowledged: REVIEW-007
project_status: PHASE_1_2A_LISTENING_READY_FOR_REVIEW__PHASE_1_1_DEVICE_ACCEPTANCE_PENDING_OWNER

> The owner's brief for this phase addressed the implementer as "Codex"; this
> work was done by Claude Code, and commits carry its attribution. The
> previous handoff, `PHASE1-006` by Codex for PR #4, is in Git history.
> `review_requested_for_sha` is the last commit that changes application
> code; the commit carrying this file changes only this file.

## Baseline acknowledged

- `main` at `8e4729f`. PR #3 (merge `a4af15f`) and PR #4 (merge `af693b4`)
  are merged. REVIEW-007 approved both; CI on the merge passed 169 tests and
  built the APK.
- Phase 1.1 device acceptance is with the owner and is **not** claimed here.
  No owner device results for Phase 1.1 had reached the repository when this
  was written.

## This PR: Phase 1.2A — listening library and dialogue player

### Content (v1.1.0)

Six original dialogues, all `author_reviewed`, in
`assets/content/v1/dialogues/`, listed in `curriculum.json`:

- four Pre-A1 and two A1-U1;
- 29 turns and 31 comprehension questions;
- each linked to the lessons it builds on, and unlocking when all of them
  are completed.

Content lessons, ids and activities are unchanged. The version bump is for
the added dialogues.

### Player (`lib/features/listening/`)

- **`DialoguePlayer`:** plays each turn as a separate utterance via a new
  `SpeechService.speakAndWait`, which uses flutter_tts `awaitSpeakCompletion`.
- **Highlighting is per turn.** There is no word-timing data, so none is claimed.
- **Pause / resume:** pause stops the voice; resume restarts the interrupted
  sentence, because Android TTS cannot resume mid-sentence reliably. The UI
  says so.
- **Stale playback:** a generation counter guarantees a stale playback loop
  can never move the state after another action.
- **Controls:** sentence replay, stop, and speeds of 60 %, 80 % and normal,
  multiplying the learner's rate setting.
- **Transcript and Arabic translation** are hidden by default, with toggles.
  English is shown only with the existing setting.
- **Only `turn.es` is ever spoken.**
- **No Spanish voice:** an explicit notice, and the transcript is forced on.
- **Saving and links:** any sentence can be saved to «عباراتي» (new
  `PhraseSource` kind `dialogue`). Vocabulary chips open the vocabulary sheet;
  grammar opens the note.
- **Comprehension questions:** choice, "who said it", and dictation. Audio is
  played and the sentence is not shown. They run in the existing
  `ExerciseRunner` (failure-safe saves, one retry, first-try scoring) and are
  stored as `activity_attempts` with context `listening`. The result screen
  says it is practice, not a level test.

### No schema change

Dialogue progress is derived from attempts: the latest first attempt per
question id. **Schema v5 is reserved for assessments (PR 1.2B).**

### Validation

New dialogue rules in `ContentValidator`, each proven by a negative test:

- ids are unique;
- level, unit and lessons exist and agree;
- vocabulary exists and is taught by the linked lessons or earlier;
- grammar references exist;
- speakers are known, and at least two of them speak;
- no Arabic in `es`, and balanced `¿?` / `¡!`;
- questions have valid answers, distinct choices and existing turns.

### Defect found by the new tests and fixed

A comprehension run finishing in under one second logged no study session,
so today's plan would not count it. A finished run now logs at least one
second.

## Verification

Local, at `cb1476a`:

| Check | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test tool test_screenshots` | 0 changed |
| `flutter analyze --fatal-infos` | No issues |
| `dart run tool/validate_content.dart` | v1.1.0 OK — 6 dialogues, 29 turns, 31 questions |
| `flutter test` | **207 passed** (baseline 169), 2 full runs |
| Drift regeneration | identical to committed file |

GitHub Actions on `cb1476a` (run 44025615075):

| Job | Result |
|---|---|
| Format, analyze, content, tests | success |
| Android debug APK | success |

New tests:

- `test/dialogue_player_test.dart` (9): ordering, pause/resume, replay
  takeover, stop, speed, no voice, dispose.
- `test/listening_content_test.dart` (23): shipped content, 15 validator
  negatives, question building, progress derivation.
- `test/listening_flow_test.dart` (6): lock/unlock, play order, toggles,
  replay, Arabic never spoken, saving a sentence, the no-voice fallback,
  questions recorded and completion shown, the Practice entry.

Screenshots: `docs/screenshots/19_listening_library.png` and
`20_dialogue_player.png`. Also added: `docs/LINGUISTIC_QA.md`, a checklist
for the human Spanish reviewer.

## Not verified — device checklist for this build

Record the commit, device, Android version, expected and actual result, and
pass/fail for each:

1. Complete Pre-A1 lessons 4–5 → Practice → «مكتبة الاستماع» → «إلى الغد» opens.
2. «شغّل الحوار» plays all four sentences in order; the highlight follows.
3. Pause mid-sentence → «تابع» restarts that sentence.
4. Speed 60 % is clearly slower; normal returns to the usual rate.
5. Replay a single sentence; save one sentence and find it in «عباراتي».
6. Answer the questions; the library then shows the score.
7. With no Spanish voice installed, the notice appears and the transcript is shown.

**Specific risk:** whether every Android TTS engine completes `speak` when
`awaitSpeakCompletion` is on. If one does not, the dialogue stops after the
first sentence. This is the most important thing to check on the device.

## Specific review request

1. The honest-limits design: per-turn highlighting, resume restarting the
   sentence, no mid-sentence resume claimed.
2. Deriving dialogue progress from attempts instead of a new table.
3. The validator's "taught by its lessons or earlier" rule.

## Next

PR 1.2B (assessment foundation, schema v5) is in progress on
`feat/phase-1.2b-assessments`, stacked on this branch. Then 1.2C (difficulty
estimator, writing quality) and the A1 units. I will not merge; merging is
the owner's decision.
