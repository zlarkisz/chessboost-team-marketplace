---
description: Scaffold a planned bounded context in apps/server from the game/boost template
argument-hint: <bc-name>
disable-model-invocation: true
---

# Scaffold bounded context: $ARGUMENTS

## Input

`$ARGUMENTS` is the name of ONE bounded context. It must match a folder name in
`apps/server/src/` exactly.

- Empty → list contexts whose `README.md` says `**Status:** planned` and ask which one.
  Do not pick one yourself.
- Does not match a folder exactly (wrong case, singular/plural, typo) → stop and ask,
  suggesting the closest existing name. Do not correct it silently.
- More than one name → stop and ask which single context to scaffold; one context
  per run.

## Preconditions

Check all of these before creating anything. If any fails — stop, report which one
and why, change nothing.

- `apps/server/src/<bc>/README.md` exists and contains `**Status:** planned`.
  - `**Status:** scaffolded` → already scaffolded, report and stop.
  - No README or no `**Status:**` line → state unknown, report and stop.
- Working tree is clean (`git status --porcelain` is empty). If not → ask me to
  commit or stash first.
- Current branch is not `main`. If it is → stop and suggest `feat/scaffold-<bc>`.
- Baseline: run `make arch`, it must pass. Note the number of modules cruised —
  Verify compares against it.

## Read first

Use the existing scaffolded contexts as the source of truth for structure and style —
do not invent a different layout.

- `apps/server/src/game/` and `apps/server/src/boost/` — reference scaffolds.
- `apps/server/src/app.module.ts` — how modules are registered.
- `apps/server/src/<bc>/README.md` — vocabulary, events, purpose of this context.
- `docs/bc-map.md` — relationships with other contexts.
- `.claude/rules/game.md` — reference for the rules file;
  `.claude/rules/server-architecture.md` — layer rules the scaffold must respect.

## Create

Mirror `game/` exactly — nothing more.

- `apps/server/src/<bc>/<bc>.module.ts` — empty Nest module, same shape as
  `game.module.ts`. Class name: PascalCase of the folder name + `Module`
  (`match` → `MatchModule`, `notifications` → `NotificationsModule`).
- `domain/`, `application/`, `infrastructure/`, `presentation/` — each with an
  empty `.gitkeep`. No other files in layers.
- `.claude/rules/<bc>.md` — same structure as `rules/game.md`:
  frontmatter `paths: ["apps/server/src/<bc>/**"]`, title, one-line purpose,
  `## Boundaries`, `## Prohibitions`.
  - Fill only what follows from the context README: purpose, what it publishes
    and listens to (via `shared/events` only).
  - Prohibitions: the standard cross-BC rule (no imports from other contexts,
    only `shared/events`).
  - Anything the README does not state → write `TODO:` instead of inventing rules.

## Modify

Keep each edit minimal — change only the lines listed.

- `apps/server/src/app.module.ts` — add the import after the existing ones and append
  `<Bc>Module` to the end of `imports`. Do not reorder existing entries.
- `apps/server/src/<bc>/README.md` — `**Status:** planned` → `**Status:** scaffolded`; replace
  the `Planned — …` line with the `Layers: …` line exactly as in `game/README.md`.
- `docs/bc-map.md` — set this context's `Status` cell to `scaffolded`.
- `ARCHITECTURE.md` and `CLAUDE.md` — move the context from the planned list to the
  scaffolded list. Keep the existing wording.

## Do not

- Write any domain logic, entities, services, controllers or DTOs — empty scaffold only.
- Add `providers`, `controllers`, `imports` or `exports` to the new module.
- Import from other bounded contexts or touch their files.
- Install, remove or upgrade packages; edit `package.json` or `pnpm-lock.yaml`.
- Edit `.dependency-cruiser.cjs`, `tsconfig.json` or any rule in `.claude/rules/`
  other than the new `<bc>.md` — to make a check pass or otherwise.
- Edit files not listed in Create / Modify. If you notice another place that
  mentions this context's status, name it in the report — do not edit it.

## Verify

Run both and show the output:

- `make typecheck` — passes with no errors.
- `make arch` — `no dependency violations found` AND exactly one module more than the
  baseline (the new `<bc>.module.ts`). A green check with an unchanged or zero count
  is a failure — it means the new module was not picked up.

If a check fails:

1. One fix attempt, only inside the files you created in this run.
2. Still failing → stop. Do not revert, do not commit; show the output and what you
   tried, and wait for me.

## Commit

Only after Verify passes.

1. Stage only the files from Create and Modify, by explicit path — never `git add .`
   or `-A`.
2. Show `git diff --cached --stat` and the commit message:
   `chore: scaffold <bc> bounded context`
3. Wait for my "yes", then commit. Do not push.

Final report: files created, files modified, both check outputs, any other status
mentions you noticed (see Do not).