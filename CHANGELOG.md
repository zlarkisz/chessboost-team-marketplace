# Changelog

All notable changes to plugins in this marketplace. Format:
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/). Breaking changes go under `### Breaking` at the top
of a release and always mean a major bump.

## chessboost-toolkit

### [1.0.0] — 2026-10-27

#### Added

- `/chessboost-toolkit:scaffold-context <bc>` — scaffolds a planned bounded context in
  `apps/server/src/<bc>/` from the `game`/`boost` template, with `make typecheck` + `make arch`
  verification.
- `PreToolUse` hook `domain-import-guard` (`Edit|Write`) — blocks npm, `@nestjs/*`, `shared/`
  and cross-context imports in `<bc>/domain/`; isolated tests in `hooks/tests/`.
