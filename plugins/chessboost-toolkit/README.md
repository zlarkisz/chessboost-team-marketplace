# chessboost-toolkit

## Purpose

Claude Code tooling for the chessboost monorepo: scaffold planned bounded contexts
from the `game`/`boost` template, keep every `<bc>/domain/` framework-free, protect the
architecture checks from being loosened, keep raw color values out of `.vue` files, and
record architecture decisions as ADRs.

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

| Skill | Triggers | What it does |
|---|---|---|
| `adr` | A decision with real alternatives is made or needs writing down — library or pattern choice, data-model or event-contract shape, a boundary between contexts; "write an ADR", "record this decision". | Writes `docs/adr/NNNN-<slug>.md` in the format of ADR 0001 (Context / Decision / Alternatives considered / Consequences), numbering it after the highest existing ADR. Asks for missing reasons instead of inventing them; marks a replaced ADR `superseded by NNNN`; does not commit. |

## Hooks

| Event | Matcher | Script | Effect |
|---|---|---|---|
| `PreToolUse` | `Edit\|Write` | `hooks/domain-import-guard.mjs` | Blocks (exit 2) writes to `apps/server/src/<bc>/domain/**` that import npm packages, `@nestjs/*`, `shared/` or another context, naming the reason for each import. |
| `PreToolUse` | `Edit\|Write` | `hooks/arch-rules-guard.mjs` | Blocks (exit 2) any edit of `.dependency-cruiser.cjs` and `tsconfig*.json`, so a failing check gets fixed in code, not by loosening the rule. Rule changes are made by hand. |
| `PreToolUse` | `Edit\|Write` | `hooks/raw-color-guard.mjs` | Blocks (exit 2) writes to `*.vue` whose new text contains a raw color — `#hex` (3/4/6/8 digits) or `rgb()`/`rgba()`/`hsl()`/`hsla()`/`oklch()`/`oklab()`/`lab()`/`lch()`/`hwb()`. Colors live only in `apps/web/app/assets/css/tailwind.css` as semantic roles. `href="#…"`/`to="#…"` anchors and HTML entities pass; named colors (`red`) are not checked. |

All hooks see only the `Edit` and `Write` tools — a change made through `Bash` (e.g. `sed -i`) is
not intercepted.

Isolated tests: `node hooks/tests/run.mjs` — fixtures in `hooks/tests/fixtures/<hook>/`,
`block-*` → exit 2, `pass-*` → exit 0.
