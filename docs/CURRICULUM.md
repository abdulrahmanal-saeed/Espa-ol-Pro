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
- **Arabic etymologies.** The [RAE/ASALE entry for *hasta*](https://dle.rae.es/hasta)
  traces it through Andalusi Arabic to classical Arabic حتّى, with Latin
  influence. The [entry for *cero*](https://dle.rae.es/cero) traces it back
  through Italian, Late Latin and Andalusi Arabic to classical Arabic صِفْر.

## Map

Pre-A1 is a preparatory stage, not a DELE level.

| Level | Unit | Status |
|---|---|---|
| **Pre-A1** | Sounds and letters (3 lessons) | ✅ available |
| | Greetings and introductions (3 lessons) | ✅ available |
| | Numbers and the first sentence (3 lessons) | ✅ available |
| **A1** | Introducing yourself and your work (3 lessons) | ✅ available |
| | Family and people (4 lessons) | ✅ available (content 1.2.0) |
| | Daily routine and time (4 lessons) | ✅ available (content 1.2.0) |
| | Food and shopping (4 lessons) | ✅ available (content 1.3.0) |
| | City and basic travel (4 lessons) | ✅ available (content 1.3.0) |
| | At the workplace | planned |
| **A2** | Services · The past · Plans and future · Preferences and comparison · Simple work conversations | planned |
| **B1** | Opinion and reasoning · Narration · Solving client problems · Professional correspondence | planned |
| **B2** | Meetings · Presentations · Job interviews · Discovery and negotiation · Explaining technical services | planned |
| **C1** | Persuasion · Precise professional writing · Advanced listening and accents | planned |
| **C2** | Precision and nuance · Professional and academic discourse | planned |

"Planned" units exist in `curriculum.json` with titles and objectives so the
whole road is visible in the app, clearly labelled "قيد الإعداد". They contain
no lessons and are never counted as progress.

## Shipped lessons (content v1.0.2; unchanged in v1.1.0)

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
| 13 | My family | 9 | tener (tengo/tienes/tiene); los padres = parents |
| 14 | Age and possessives | 8 | ¿Cuántos años tienes?; mi/mis, su/sus; casado |
| 15 | What is he/she like? | 8 | adjective agreement; simpático (false friend) |
| 16 | My work team | 8 | este/esta es…; experience and reliability |
| 17 | What time is it? | 8 | es la una / son las…; y media, menos cuarto; a las… |
| 18 | Days of the week | 9 | el lunes vs los lunes; hoy |
| 19 | My normal day | 8 | yo forms -ar/-er; como ≠ ¿cómo?; por la mañana |
| 20 | Making an appointment | 8 | ¿Le va bien…?; de acuerdo; lo siento; ocupado/libre |
| 21 | At the café | 9 | querer (quiero/quieres/quiere); el agua; té ≠ te; para mí |
| 22 | At the restaurant | 8 | ordering a meal; ¿Y para beber?; la cuenta |
| 23 | How much is it? | 9 | prices to 100; caro/barato; cash or card |
| 24 | An order for the office | 8 | necesito; ¿Para cuántas personas?; la factura ≠ la cuenta |
| 25 | Where is…? | 9 | estar for location (estoy/estás/está); cerca/lejos |
| 26 | Directions | 7 | a la derecha/izquierda; todo recto; del/al |
| 27 | Transport | 8 | ir (voy/vas/va); ir a + place, en + vehicle |
| 28 | At the hotel | 8 | tengo una reserva a nombre de…; pasaporte, llave |

Totals: 101 items, 299 activities (172 graded), 14 grammar notes.

## Lesson shape

`note` (concept) → `teach` (item, audio, examples, connections) → recognition
→ listening → guided production (fill, order) → free production (type,
dictation) → situational reply or reading → listen-and-repeat → summary →
FSRS cards. The validator enforces: every item taught before practised and
practised at least once in a graded activity; ≥ 6 graded activities of ≥ 4
types; at least one production and one listening activity.

## Review status — read this

The Phase 1 author review covered all 12 lessons across the four available
units. It checked prerequisite order, Arabic explanations and translations,
Spanish examples, and how listening, dictation, written and situational
prompts match their answers. The lesson and reference notes now qualify
pronunciation, word stress, and register. The A1 client prompt now uses
`usted` in both the displayed prompt and its audio text.

The [Instituto Cervantes A1–A2 inventory](https://cvc.cervantes.es/ensenanza/biblioteca_ele/plan_curricular/niveles/05_funciones_inventario_a1-a2.htm)
supports the sequence of greetings and introductions. The
[RAE orthography reference](https://www.rae.es/diccionario-estudiante/docs/ortografia.pdf)
describes the stress rules behind the simplified introductory explanations.
The content remains `author_reviewed`. Review by a native Spanish teacher
is pending.

Accent: default voice es-MX (seseo); notes point out Castilian differences
(c/z as θ) where they matter.

## Dialogues (content v1.1.0)

| Id | Level | Built on | Situation |
|---|---|---|---|
| `dlg_pa1_saludo` | Pre-A1 | lessons 4–5 | Colleagues part at the end of the day |
| `dlg_pa1_presentacion` | Pre-A1 | lessons 5–6 | Formal first meeting with a client (usted) |
| `dlg_pa1_telefono` | Pre-A1 | lessons 7–8 | Exchanging phone numbers digit by digit |
| `dlg_pa1_origen` | Pre-A1 | lesson 9 | Informal introductions at a language course (tú) |
| `dlg_a1_idiomas` | A1 | lessons 10–11 | Languages and jobs at a trade fair |
| `dlg_a1_recepcion` | A1 | lessons 11–12 | A client arrives at reception and is introduced |
| `dlg_a1_familia` | A1 | lessons 13–14 | Colleagues talk about children and siblings |
| `dlg_a1_equipo` | A1 | lessons 15–16 | Presenting the team to a visiting client |
| `dlg_a1_rutina` | A1 | lessons 17–19 | New colleagues compare their working hours |
| `dlg_a1_cita` | A1 | lessons 18, 20 | Rescheduling a client meeting by phone |

| `dlg_a1_cafeteria` | A1 | lessons 21–22 | Coffee with a client before a meeting |
| `dlg_a1_pedido` | A1 | lessons 23–24 | Ordering catering with an invoice |
| `dlg_a1_direccion` | A1 | lessons 25–26 | Asking the way to a client's office |
| `dlg_a1_hotel` | A1 | lessons 27–28 | Business-trip hotel check-in |

Checkpoints `chk_a1_u4` and `chk_a1_u5` close the food and travel units.
Checkpoints `chk_a1_u2` and `chk_a1_u3` (10 questions, 3 can-dos each) close
the new units; each plays one dialogue sentence.

All are original and `author_reviewed`; see [LINGUISTIC_QA.md](LINGUISTIC_QA.md).
