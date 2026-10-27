# chessboost-toolkit

## Purpose

Claude Code tooling for the chessboost monorepo: scaffold planned bounded contexts
from the `game`/`boost` template and keep every `<bc>/domain/` framework-free.

## Install

From the marketplace (Claude Code 2.1.275+):

```sh
/plugin install chessboost-toolkit --marketplace zlarkisz/chessboost-team-marketplace
```

Or in two steps:

```sh
/plugin marketplace add zlarkisz/chessboost-team-marketplace
/plugin install chessboost-toolkit@chessboost
```

For the whole team, add `--scope project` to the install command — it records the plugin in the
repo's `.claude/settings.json`.

Local development (no install, current session only):

```sh
claude --plugin-dir ./plugins/chessboost-toolkit
```

## Commands

| Command | What it does |
|---|---|
| `/chessboost-toolkit:scaffold-context <bc>` | Scaffolds a `planned` context in `apps/server/src/<bc>/`: empty Nest module, 4 layer folders, `.claude/rules/<bc>.md`, status updates in docs. Runs `make typecheck` + `make arch`, asks before committing. Manual only (`disable-model-invocation`). |

## Skills

—

## Hooks

| Event | Matcher | Script | Effect |
|---|---|---|---|
| `PreToolUse` | `Edit\|Write` | `hooks/domain-import-guard.mjs` | Blocks (exit 2) writes to `apps/server/src/<bc>/domain/**` that import npm packages, `@nestjs/*`, `shared/` or another context. |

Isolated tests: `node hooks/tests/run.mjs` (6 fixtures, `block-*` → 2, `pass-*` → 0).
