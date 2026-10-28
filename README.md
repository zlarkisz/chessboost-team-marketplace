# chessboost-team-marketplace

## What it is

A Claude Code plugin marketplace for the [chessboost](https://github.com/zlarkisz/chessboost)
monorepo — plugins that keep its architecture in shape: scaffolding new bounded contexts and
guarding the purity of `<bc>/domain/`.

## Add it to Claude Code

```sh
/plugin marketplace add zlarkisz/chessboost-team-marketplace
/plugin install chessboost-toolkit@chessboost --scope project
```

`--scope project` records the plugin in the repo's `.claude/settings.json`, so teammates get it
after `git pull`. To update: `/plugin marketplace update chessboost`, then `/plugin update`.

## Plugins

| Plugin | Version | What it does |
|---|---|---|
| [`chessboost-toolkit`](plugins/chessboost-toolkit) | 1.0.0 | `/chessboost-toolkit:scaffold-context` scaffolds a planned bounded context; a `PreToolUse` hook blocks framework imports in `<bc>/domain/` |

## Maintainers

- [@zlarkisz](https://github.com/zlarkisz) — Gleb Bufin

## Contributing

1. Branch off `main`, change files under `plugins/<name>/`. Use Conventional Commits
   (`feat:`, `fix:`, `feat!:` …) — the release changelog is built from them.
2. Run `claude plugin validate .` locally → open a PR → green CI → review.
3. Don't bump `version` or edit `CHANGELOG.md` by hand — that happens on release.

## Releasing

```sh
bin/release.sh prepare <plugin>   # on an up-to-date main: changelog entry, version bump, release PR
# review the release PR, merge it once CI is green
git switch main && git pull
bin/release.sh tag <plugin>       # tags <plugin>@<version> on main and pushes the tag
```

`prepare` runs Claude headlessly to write the `CHANGELOG.md` entry from the plugin's commits since
its last tag; the script then checks the result and bumps `version` in both manifests. The agent
may only run `git log` and edit `CHANGELOG.md`; a run is capped at 10 turns, $0.50 and 3 minutes.
Needs `claude` (logged in, or `ANTHROPIC_API_KEY`), `jq` and `gh`.

Hooks, `bin/` and `.mcp.json` run with the user's permissions — PRs touching them are reviewed
against [SECURITY.md](SECURITY.md).

## Contact

Questions and bugs — [GitHub Issues](https://github.com/zlarkisz/chessboost-team-marketplace/issues).
Vulnerabilities — see [SECURITY.md](SECURITY.md).
