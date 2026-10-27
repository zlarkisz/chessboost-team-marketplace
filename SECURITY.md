# Security policy

Plugins in this marketplace run with the permissions of the user who installs them — there is
no sandbox. Hooks fire automatically on tool calls, `bin/` executables land in `$PATH`, and
`.mcp.json` connects Claude to external servers. Treat every change to them as a code change
with security impact.

## Supported versions

| Plugin | Supported |
|---|---|
| `chessboost-toolkit` 1.x | ✅ |

## Reporting a vulnerability

Do **not** open a public issue. Use GitHub's private reporting:
[Report a vulnerability](https://github.com/zlarkisz/chessboost-team-marketplace/security/advisories/new).

Include the plugin and version, the affected file (hook, script, `bin/`, `.mcp.json`), steps to
reproduce, and the impact.

## Response

| Step | Target |
|---|---|
| Acknowledge the report | 3 business days |
| Assess and confirm | 7 business days |
| Fix released (patch version + `CHANGELOG.md` entry) | 30 days, sooner for critical issues |

## Review checklist for plugin changes

- Hooks: matcher scope (no `.*` without a reason), no network calls, no data leaving the machine.
- `bin/`: no executables that shadow common commands (`git`, `node`, …).
- `.mcp.json`: known servers only, no hardcoded tokens.
- Scripts use `${CLAUDE_PLUGIN_ROOT}`, not hardcoded or relative paths.
- New dependencies checked for known CVEs.
