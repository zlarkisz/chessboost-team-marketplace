You are preparing release notes for the next version of one plugin in this
Claude Code plugin marketplace. Your result is a new version entry in
`CHANGELOG.md` at the repository root.

## Context

The release script appends a `<release_context>` block at the end of this
prompt with three values:

- `plugin` — the plugin to release; its files live in `plugins/<plugin>/`.
- `previous_tag` — the git tag of the last release of this plugin.
- `today` — the release date in `YYYY-MM-DD` format.

Use these values exactly as given. Do not derive them from the changelog,
the git history or your own knowledge — the script already knows them for
certain.

## Workflow

1. **Read `CHANGELOG.md`.** Find the `## <plugin>` section and study its most
   recent entry — you will copy its exact format (heading levels, dash, blank
   lines, bullet style).
2. **List the commits of this release:**
   `git log <previous_tag>..HEAD --no-merges --oneline -- plugins/<plugin>/`.
   The path filter matters: commits that do not touch the plugin (CI, repo
   docs, tooling) are not part of its release.
3. **Understand each commit.** If a subject alone does not tell you what
   changed for the user, inspect it with `git log -p -1 <sha>`.
4. **Sort the commits into sections** by their conventional-commit prefix:
   - `!` after the type (e.g. `feat!:`) or a `BREAKING CHANGE:` footer → **Breaking**
   - `feat:` → **Added**
   - `fix:` → **Fixed**
   - `refactor:`, `perf:`, `chore:` that change plugin behaviour → **Changed**
   - something removed from the plugin → **Removed**
   - `test:`, `ci:`, `docs:`, `style:` → skip; they do not change what a user
     of the plugin gets.
   Rewrite each kept commit as a short bullet that tells a plugin user what is
   different for them — not a copy of the commit subject.
5. **Insert the new entry** in `CHANGELOG.md` directly under the
   `## <plugin>` heading, above the previous version:
   `### [<version>] — <today>`, then one `#### <Section>` per non-empty section.

## Constraints

- Edit only `CHANGELOG.md`. Do not touch plugin files or version fields in
  JSON manifests — the release script bumps versions after you finish.
- Do not commit, tag or push. Your edit stays in the working tree; the
  script reviews and commits it.
- Change nothing in existing entries — only add the new one.
- Section order: `Breaking` → `Added` → `Changed` → `Fixed` → `Removed`.
  Omit sections with no bullets.
- One line per bullet, no trailing period.
- If no commit survives step 4, do not edit `CHANGELOG.md` and return an
  empty `sections` array — the script treats that as "nothing to release"
  and stops.

## Final output

When the edit is done, return a JSON object that matches the requested
schema:

- `version` — the next version, `X.Y.Z` without a prefix, bumped from the
  version in `previous_tag`:
  - any **Breaking** bullet → major (`1.4.2` → `2.0.0`);
  - otherwise any **Added** bullet → minor (`1.4.2` → `1.5.0`);
  - otherwise → patch (`1.4.2` → `1.4.3`).
- `release_date` — the `today` value from `<release_context>`.
- `sections` — one `{ "title", "items" }` object per section you wrote, in
  the same order; `items` are the bullets as written, without the leading
  `- `.

The JSON must mirror the changelog entry exactly: same version, same
sections, same bullets. The script compares them, and any mismatch fails the
release.
