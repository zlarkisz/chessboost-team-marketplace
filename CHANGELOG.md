# Changelog

All notable changes to plugins in this marketplace. Format:
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/). Breaking changes go under `### Breaking` at the top
of a release and always mean a major bump.

## chessboost-toolkit

### [1.2.0] — 2026-11-06

#### Added

- `raw-color-guard` hook — blocks raw color values (`#hex`, `rgb()`, `oklch()` and similar) in `.vue` files; use semantic role utilities such as `bg-primary` or `text-muted-foreground` instead

### [1.1.0] — 2026-11-02

#### Added

- `adr` skill — record architecture decisions as ADR documents
- `arch-rules-guard` hook — protects dependency-cruiser and tsconfig configuration from edits

### [1.0.1] — 2026-10-28

#### Fixed

- `domain-import-guard` — blocked imports now say why: leaving `domain/`, reaching into `shared/`, or importing another bounded context

### [1.0.0] — 2026-10-27

#### Added

- `/chessboost-toolkit:scaffold-context <bc>` — scaffolds a planned bounded context in
  `apps/server/src/<bc>/` from the `game`/`boost` template, with `make typecheck` + `make arch`
  verification.
- `PreToolUse` hook `domain-import-guard` (`Edit|Write`) — blocks npm, `@nestjs/*`, `shared/`
  and cross-context imports in `<bc>/domain/`; isolated tests in `hooks/tests/`.
