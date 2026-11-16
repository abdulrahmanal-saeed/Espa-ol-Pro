# Roadmap

> Short overview. The authoritative, per-requirement plan with status is
> [`AI_BRIDGE/PROJECT_PLAN.md`](../AI_BRIDGE/PROJECT_PLAN.md).

A phase is done only when its acceptance criteria are verified by tests or a
documented manual check — never because screens exist.

## Phase 1 — Educational foundation (in review)

Working app: navigation, RTL design system, lesson engine, FSRS, progress,
library, backup, Pre-A1 complete + first A1 unit. Detailed status:
`IMPLEMENTATION_STATUS.md`.

Remaining before Phase 1 can be called accepted:
- Manual run on a physical Android device (audio, keyboard, file dialogs).
- Reviewer sign-off through `AI_BRIDGE/`.

## Phase 1.x — Foundation hardening (next)

- Study reminders (local notifications).
- Listening library: graded dialogues with transcript toggle, sentence repeat
  and speed control, built from lesson dialogues.
- Unit checkpoints (task-based mini assessments) — first real CEFR evidence.
- Saved phrases; verb conjugation reference.
- Remaining A1 units (A1-U2 … A1-U6).

## Phase 2 — AI and speaking (blocked on owner decisions)

Needs: choice of LLM provider, a backend proxy to hold the key, a cost budget.
Scope: text tutor with level-aware prompt and validated structured output,
roleplay personas, writing feedback into the error notebook, recording +
shadowing playback, pronunciation assessment only if a real phoneme-level
service is selected. Ships with daily/monthly limits and a kill switch.
The LLM never writes progress or assessment records directly.

## Phase 3 — Full core curriculum

Complete A1 → B2, reading library, grammar and conjugation reference, unit and
level assessments, native-speaker review of all content
(`review_status: native_reviewed`).

## Phase 4 — Professional Spanish

Work missions (discovery call → objection → follow-up email), interview coach
from a pasted job description, meetings, negotiation, business email.

## Phase 5 — Advanced proficiency

C1/C2, regional accents, DELE-style original practice, deeper personalisation.

## Open owner decisions

1. LLM provider and monthly budget for Phase 2.
2. Whether a native Spanish teacher will review content, and when.
3. Repository visibility (currently public; the brief preferred private).
4. Primary accent stays es-MX?
