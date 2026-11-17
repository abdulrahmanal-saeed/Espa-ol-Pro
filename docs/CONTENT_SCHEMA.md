# Content package schema

Location: `assets/content/v1/`. The JSON files are the source of truth.

```
curriculum.json          version, sources, levels → units (map of the whole course)
units/<unit_id>.json     grammar notes + lessons of one *available* unit
```

## curriculum.json

```jsonc
{
  "version": "1.0.0",                       // semantic; stored with each completion
  "sources": [{ "id", "title", "license", "attribution",
                "review_status": "author_reviewed|native_reviewed|unreviewed" }],
  "levels": [{
    "id": "pre_a1|a1|a2|b1|b2|c1|c2",       // exactly these, in this order
    "code": "A1", "title_ar", "description_ar", "can_do_ar": ["…"],
    "preparatory": false,                   // true only for pre_a1
    "units": [{ "id", "title_ar", "description_ar", "objectives_ar": ["…"],
                "status": "available|planned" }]
  }]
}
```

## units/<unit_id>.json

```jsonc
{
  "grammar": [{ "id", "title_ar", "body_ar", "examples": [{ "es", "ar" }] }],
  "lessons": [{
    "id", "title_ar", "title_es", "objectives_ar": ["…"],
    "prerequisites": ["earlier_lesson_id"], "minutes": 12,
    "work_relevance_ar": "…", "source": "source_id", "grammar": ["grammar_id"],
    "items": [{
      "id", "es", "ar", "en", "pos",
      "examples": [{ "es", "ar" }],          // ≥ 1
      "note_ar", "tags": [], "work": true,
      "alt": ["other accepted written forms"],
      "syn": "group",                        // near-synonyms: never mutual distractors
      "connections": [{ "type": "arabic_origin|cognate|false_friend|pronunciation|grammar|usage", "ar" }]
    }],
    "activities": [ /* in teaching order */ ]
  }]
}
```

## Activity types

| type | fields | graded | skill |
|---|---|---|---|
| `teach` | `item` | – | – |
| `note` | `title_ar`, `body_ar`, `examples` | – | – |
| `mcq_meaning` | `item` (ES → choose AR) | ✓ | vocabulary |
| `mcq_reverse` | `item` (AR → choose ES) | ✓ | vocabulary |
| `listen_choose` | `item` (audio → choose AR) | ✓ | listening |
| `listen_pick_es` | `item` (audio → choose ES) | ✓ | listening |
| `type_es` | `item` (AR → type ES) | ✓ production | writing |
| `dictation` | `item` or `es`+`ar` | ✓ production | listening |
| `fill` | `es` with one `___`, `answer`, `ar`, optional `options`, `alt`, `explain_ar` | ✓ production | grammar / writing |
| `order` | `es`, `ar`, optional `distractors` | ✓ production | writing |
| `match` | `items` (≥ 3) | ✓ | vocabulary |
| `choice` | `prompt_ar`, `choices`, `answer` (index), optional `stimulus_es`, `audio_es`, `skill`, `choices_es`, `explain_ar` | ✓ | as given |
| `respond` | `prompt_ar`, `accepted` (≥ 1), optional `audio_es` | ✓ production | writing |
| `speak` | `item` or `es`+`ar` | self-assessed, never scored | speaking |

Activity IDs default to `<lesson_id>#<n>`; give an explicit `id` to keep
history stable when reordering.

## Validation (`dart run tool/validate_content.dart`)

Fails CI on: non-semantic version · missing licence / attribution / review
status · wrong CEFR ladder · duplicate unit / lesson / item / grammar /
activity IDs · duplicate Spanish text · missing translation, part of speech or
example · Arabic script in a Spanish field (or none in an Arabic field) ·
unbalanced `¿ ?` / `¡ !` · unknown source or grammar reference · prerequisite
that is not an earlier lesson · reference to an unknown or later item ·
practice before teach · item never taught or never practised · malformed
activity fields · fewer than 6 graded activities or 4 graded types · no
production or no listening activity.

What validation cannot prove: that the Spanish is natural and the Arabic
accurate. That is tracked by `review_status` (see `CURRICULUM.md`).

## Adding content

1. Add or edit a `units/<id>.json`; set the unit `status` to `available`.
2. Bump `version` (patch for fixes, minor for new lessons).
3. Run the validator and `flutter test`.
4. Never reuse or repurpose an existing item ID: review cards point at it.

## Dialogues (listening library, content ≥ 1.1.0)

`curriculum.json` lists dialogue files in `dialogue_files`
(`dialogues/<level>.json`). Each file holds `{ "dialogues": [ … ] }`:

```jsonc
{
  "id": "dlg_pa1_saludo",            // stable; attempts reference question ids
  "level": "pre_a1", "unit": "pa1_u2",
  "lessons": ["pa1_u2_l1", "pa1_u2_l2"], // unlocks when ALL are completed
  "title_es": "…", "title_ar": "…", "scenario_ar": "…",
  "objectives_ar": ["…"],
  "speakers": [{ "id": "laura", "name": "Laura", "role_ar": "…" }],
  "turns": [{ "id": "dlg_pa1_saludo.t1", "speaker": "laura",
              "es": "…", "ar": "…", "en": "…" }],   // only `es` is ever spoken
  "items": ["buenas_tardes"],        // vocabulary the dialogue practises
  "grammar": ["g_greetings_time"],
  "questions": [ /* see below */ ],
  "source": "original-v1"
}
```

| question `type` | fields | what the learner sees |
|---|---|---|
| `choice` | `prompt_ar`, `choices`, `answer` (index), optional `turn`, `choices_es`, `skill`, `explain_ar` | the turn's Spanish is **played, not shown**; choose |
| `speaker` | `turn` | "who said this?"; choices are the dialogue's speakers |
| `dictation` | `turn` | type what was heard |

Validation adds: unique dialogue / turn / question ids; level, unit and
lessons exist and agree; every vocabulary item exists **and is taught by the
linked lessons or earlier**; grammar references exist; known speakers, at
least two of whom speak; Spanish has no Arabic script and balanced `¿ ?` /
`¡ !`; Arabic fields contain Arabic; at least 3 questions; valid answer
indices, distinct choices, and existing turn references.

Learner state is not stored separately. A dialogue's progress is derived
from `activity_attempts` rows with `context = 'listening'` whose
`activity_id` is a question id (first attempts only, most recent run).

## Assessments (checkpoints, content ≥ 1.1.0)

`curriculum.json` lists assessment files in `assessment_files`
(`assessments/<level>.json`), each `{ "assessments": [ … ] }`:

```jsonc
{
  "id": "chk_pa1_u1", "version": 1,      // bump version when questions change
  "kind": "unit",                        // unit | level
  "level": "pre_a1", "unit": "pa1_u1",   // a level assessment has no unit
  "title_ar": "…", "intro_ar": "…",
  "can_do": [{ "id": "cd_pa1_u1_hear", "ar": "أميّز …",
               "lessons": ["pa1_u1_l1"] }],   // lessons to revisit when weak
  "questions": [{
    "id": "chk_pa1_u1.q1", "type": "choice", // choice | type | dictation
    "skill": "listening",                     // vocabulary | reading | listening | writing | grammar
    "can_do": "cd_pa1_u1_hear",
    "prompt_ar": "…", "audio_es": "perro",    // or stimulus_es / stimulus_ar
    "choices": ["perro", "pero"], "answer": 0, "choices_es": true
  }],
  "source": "original-v1"
}
```

| `type` | required | graded by |
|---|---|---|
| `choice` | `prompt_ar`, ≥ 2 distinct `choices`, valid `answer` | exact option text |
| `type` | `prompt_ar`, `accepted` | the answer evaluator; missing accents = meaning right, spelling recorded apart |
| `dictation` | `audio_es` | as `type`, against `audio_es` |

Optional on any question:

- `dialogue_turn`: the id of a dialogue turn (content ≥ 1.1.1). The question
  plays exactly that sentence (it becomes `audio_es`). The dialogue must
  belong to the checkpoint's unit (or level for a level assessment), and the
  question must measure listening.
- `explain_ar`: shown on the result screen after a wrong answer, never
  during the checkpoint. Every grammar question has one.

Changing a checkpoint's questions requires bumping its `version`; results
taken against an earlier version are shown as recorded, with a note.

Validation: unique ids; `version ≥ 1`; title and intro present; known source;
a `unit` checkpoint names an available unit of its level, one per unit; a
`level` assessment names no unit; each can-do has Arabic text, lessons inside
its unit/level, and **at least 2 questions** as evidence; at least 8 questions
covering at least 3 skills; speaking is rejected (not objectively measurable);
Spanish fields have no Arabic script and balanced `¿ ?` / `¡ !`. Every rule is
proven on a broken copy in `test/assessment_content_test.dart`.

## Verb reference (content ≥ 1.4.0)

`curriculum.json` names one file in `verb_file` (`verbs.json`):

```jsonc
{ "verbs": [{
  "id": "hablar", "infinitive": "hablar", "ar": "يتكلم",
  "regular": true,                      // regular verbs are machine-checked
  "present": { "yo": "hablo", "tu": "hablas", "el": "habla",
               "nosotros": "hablamos", "vosotros": "habláis", "ellos": "hablan" },
  "note_ar": "…", "examples": [{ "es": "…", "ar": "…" }],
  "lessons": ["a1_u1_l1"]               // where it is taught
}] }
```

Validation: unique ids; Arabic gloss; all six persons present, no Arabic
script, no unknown person keys; **a regular verb's six forms must equal the
-ar / -er / -ir rules exactly** (so a typo such as *hablámos* is rejected);
at least one existing lesson and one example. Irregular verbs are entered by
hand and marked `"regular": false`.

## Level assessments

`"kind": "level"` with no `unit`. Its can-dos may point at lessons anywhere in
the level. It opens only when every available lesson of the level is
completed, and appears at the end of the level on the learning path.
