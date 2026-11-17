# Linguistic QA checklist

For a qualified human reviewer of the Spanish and Arabic content. Automated
validation (`dart run tool/validate_content.dart`) checks structure only; it
cannot tell whether a sentence is natural, a translation is accurate or a
register is right. Content stays `author_reviewed` in `curriculum.json` until
a human has worked through this list.

Scope at content v1.1.0: 12 lessons (`assets/content/v1/units/`), 14 grammar
notes, 6 dialogues (`assets/content/v1/dialogues/`).

## For every Spanish sentence

- [ ] Grammatical, and natural for the stated situation and speakers.
- [ ] Accents, `ñ`, `¿ ?` and `¡ !` correct.
- [ ] Agreement in gender and number (`encantado/encantada`, `bienvenido/a`).
- [ ] Register matches the scene: `usted` with clients, strangers and
      managers; `tú` with peers and friends. The same speaker stays consistent.
- [ ] Verb forms correct for the person.
- [ ] Uses only language the learner has met by that point (the validator
      checks vocabulary ids, not grammar or set phrases inside sentences).
- [ ] No regionalism presented as universal without a note. The default
      voice is es-MX.

## For every Arabic translation

- [ ] Accurate meaning, not word-for-word.
- [ ] Gender of the addressee correct (أنتَ / أنتِ, حضرتك).
- [ ] Natural Modern Standard Arabic suitable for an adult learner.

## Explanations and claims

- [ ] Pronunciation descriptions are qualified where they vary by region.
- [ ] No absolute rule stated where exceptions exist.
- [ ] Etymologies (`hasta` ← حتّى, `cero` ← صِفْر) checked against an
      etymological dictionary (e.g. the RAE's DLE); otherwise removed.

## Dialogues

- [ ] Each turn fits its speaker's role and the scenario.
- [ ] The Arabic for each turn matches its Spanish.
- [ ] Every comprehension question is answerable from what is heard, has
      exactly one defensible answer, and its explanation is correct.
- [ ] Dictation turns are sensible to write from listening at this level.

## Recording the review

When a lesson, dialogue or unit is reviewed, record who reviewed it, when,
and what changed. Promote the source's `review_status` to `native_reviewed`
only when the whole source has been reviewed.
