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

1. Branch off `main`, change files under `plugins/<name>/`.
2. Any behaviour change bumps `version` in **both** `plugins/<name>/.claude-plugin/plugin.json`
   and `.claude-plugin/marketplace.json` — CI checks that they match. Breaking change → major.
3. Add an entry to `CHANGELOG.md`.
4. Run `claude plugin validate .` locally → open a PR → green CI → review.
5. After merge, tag `<plugin>@<version>` and `git push --tags`.

Hooks, `bin/` and `.mcp.json` run with the user's permissions — PRs touching them are reviewed
against [SECURITY.md](SECURITY.md).

## Contact

Questions and bugs — [GitHub Issues](https://github.com/zlarkisz/chessboost-team-marketplace/issues).
Vulnerabilities — see [SECURITY.md](SECURITY.md).
