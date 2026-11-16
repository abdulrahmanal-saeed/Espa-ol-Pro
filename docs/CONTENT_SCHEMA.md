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
