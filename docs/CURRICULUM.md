# Curriculum

## Principles

- **Objectives first.** Each level lists CEFR-style "can-do" outcomes; units
  and lessons exist to serve them. Aligned to the CEFR Companion Volume and the
  thematic scope of the Instituto Cervantes Plan Curricular. No textbook,
  exam or third-party lesson text is copied: all content is original.
- **Sentence-first vocabulary.** Every item carries at least one example
  sentence with translation, and is practised in recognition, listening and
  production.
- **Retrieval over recognition.** Every lesson must contain production
  (typing, ordering, dictation, situational reply) and listening; multiple
  choice is used for first contact, not as the main proof of learning.
- **Use what the learner already knows.** Arabic and English connections are
  first-class content (`connections`): Arabic-origin words, cognates, false
  friends, pronunciation transfer (j ≈ خ, tapped r = ر, Castilian z ≈ ث, the
  e/i and o/u contrasts Arabic lacks), grammar parallels (gender agreement,
  usted ≈ حضرتك, profession without article).
- **Work from day one.** Professional vocabulary is tagged `work` and
  introduced from Pre-A1 (oficina, cliente, cita), growing into the
  "Spanish for Work" track.
- **Etymology is never invented.** Only two Arabic-origin claims are made
  (`hasta` ← حتّى, `cero` ← صِفْر), both as given by the RAE dictionary.

## Map

Pre-A1 is a preparatory stage, not a DELE level.

| Level | Unit | Status |
|---|---|---|
| **Pre-A1** | Sounds and letters (3 lessons) | ✅ available |
| | Greetings and introductions (3 lessons) | ✅ available |
| | Numbers and the first sentence (3 lessons) | ✅ available |
| **A1** | Introducing yourself and your work (3 lessons) | ✅ available |
| | Family and people · Daily routine and time · Food and shopping · City and basic travel · At the workplace | planned |
| **A2** | Services · The past · Plans and future · Preferences and comparison · Simple work conversations | planned |
| **B1** | Opinion and reasoning · Narration · Solving client problems · Professional correspondence | planned |
| **B2** | Meetings · Presentations · Job interviews · Discovery and negotiation · Explaining technical services | planned |
| **C1** | Persuasion · Precise professional writing · Advanced listening and accents | planned |
| **C2** | Precision and nuance · Professional and academic discourse | planned |

"Planned" units exist in `curriculum.json` with titles and objectives so the
whole road is visible in the app, clearly labelled "قيد الإعداد". They contain
no lessons and are never counted as progress.

## Shipped lessons (content v1.0.0)

| # | Lesson | New items | Focus |
|---|---|---|---|
| 1 | The five vowels | 7 | a e i o u; mesa ≠ misa |
| 2 | Letters unlike English | 7 | h, ñ, ll, j, g |
| 3 | c, z, qu, r — and stress | 8 | pero ≠ perro; accent rules |
| 4 | Greetings and farewells | 7 | time-of-day greetings; buenos/buenas |
| 5 | How are you? Courtesy | 8 | tú vs usted; ¿ ? |
| 6 | What's your name? | 9 | me llamo; encantado/a; señor/a |
| 7 | Numbers 0–10 | 10 | counting, listening to digits |
| 8 | Numbers 11–20, phone | 10 | dieci- pattern; phone number |
| 9 | First sentence: ser | 9 | soy/eres/es; soy de…; negation |
| 10 | Nationality and languages | 9 | gender agreement; hablar |
| 11 | What do you do? | 8 | trabajar; profession w/o article |
| 12 | First professional contact | 9 | le presento a…; ¿En qué puedo ayudarle? |

Totals: 101 items, 299 activities (172 graded), 14 grammar notes.

## Lesson shape

`note` (concept) → `teach` (item, audio, examples, connections) → recognition
→ listening → guided production (fill, order) → free production (type,
dictation) → situational reply or reading → listen-and-repeat → summary →
FSRS cards. The validator enforces: every item taught before practised and
practised at least once in a graded activity; ≥ 6 graded activities of ≥ 4
types; at least one production and one listening activity.

## Review status — read this

All content is `author_reviewed`: written and checked by the AI implementer
and machine-validated for structure. **It has not been reviewed by a native
Spanish teacher.** The app states this in Settings. Promotion to
`native_reviewed` requires a human review and is a Phase 3 gate.

Accent: default voice es-MX (seseo); notes point out Castilian differences
(c/z as θ) where they matter.
