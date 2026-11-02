---
name: adr
description: Records an architecture decision for the chessboost repo as a numbered ADR in docs/adr/. Use when a decision with real alternatives has been made or needs writing down — a library or pattern choice, a data-model or event-contract shape, a boundary between bounded contexts — or when the user asks to "write an ADR" or "record this decision". Not for routine changes that had no alternatives.
---

# Record an architecture decision

An ADR captures one decision, the options that lost and why, so the reasoning survives after the
conversation is gone. Follow the steps in order.

## 1. Check that it deserves an ADR

The decision must have at least two real alternatives. If there was only one sensible option, or it
is an implementation detail inside one file, say so and stop — chessboost keeps ADRs for decisions
with alternatives only.

## 2. Collect the content

Take everything from the conversation and the repo; do not invent it.

- **Context** — the facts and constraints that forced a decision.
- **Decision** — what was chosen, stated so it can be checked in code.
- **Alternatives** — each rejected option with the concrete reason it lost.
- **Consequences** — what becomes easier, harder or required because of it.

If the reason an alternative was rejected is missing, ask for it. An ADR without reasons for the
rejected options is the main failure mode.

## 3. Number and name the file

List `docs/adr/`, take the highest `NNNN-` prefix and add one, zero-padded to four digits. Name the
file `docs/adr/NNNN-<short-kebab-slug>.md`.

## 4. Write it

Use the structure in [template.md](template.md) — it mirrors `docs/adr/0001-initial-setup.md`.

- `Status: proposed`, unless the user has said the decision is final — then `accepted`.
- `Date:` today, `YYYY-MM-DD`.
- Bullets for facts, short paragraphs for the decision. No section left empty.

If the new decision replaces an earlier ADR, add `- Supersedes: NNNN` to the new file and change the
old file's status to `superseded by NNNN`. That status line is the only edit allowed in an old ADR.

## 5. Hand over

Show the path of the new file and a two-line summary of the decision. Do not commit, and do not
change code or other docs to match the decision — that is separate work.
