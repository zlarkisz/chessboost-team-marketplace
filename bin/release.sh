#!/usr/bin/env bash
# Usage:
#   bin/release.sh prepare <plugin>   changelog via Claude → version bump → PR
#   bin/release.sh tag <plugin>       after the PR is merged: tag main and push the tag

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

MODE="${1:-}"
PLUGIN="${2:-}"
PROMPT_FILE="bin/release-prompt.md"
MARKETPLACE_JSON=".claude-plugin/marketplace.json"
PLUGIN_JSON="plugins/$PLUGIN/.claude-plugin/plugin.json"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 not found in PATH"
}

[[ "$MODE" == "prepare" || "$MODE" == "tag" ]] || die "usage: bin/release.sh prepare|tag <plugin>"
[[ -n "$PLUGIN" ]] || die "usage: bin/release.sh prepare|tag <plugin>"
[[ -f "$PLUGIN_JSON" ]] || die "unknown plugin '$PLUGIN': $PLUGIN_JSON not found"

require_cmd git
require_cmd jq
require_cmd gh

[[ "$(git branch --show-current)" == "main" ]] || die "run from main"
[[ -z "$(git status --porcelain)" ]] || die "working tree is not clean — commit or stash first"
git fetch --quiet origin main --tags
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || die "main is not in sync with origin/main — pull first"

PREVIOUS_TAG="$(git tag --list "$PLUGIN@*" --sort=-v:refname | head -n 1)"
[[ -n "$PREVIOUS_TAG" ]] || die "no previous tag '$PLUGIN@*' — tag the first release by hand"

CHANGELOG_SCHEMA='{
  "type": "object",
  "properties": {
    "version": { "type": "string", "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$" },
    "release_date": { "type": "string", "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" },
    "sections": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": { "enum": ["Breaking", "Added", "Changed", "Fixed", "Removed"] },
          "items": { "type": "array", "minItems": 1, "items": { "type": "string" } }
        },
        "required": ["title", "items"]
      }
    }
  },
  "required": ["version", "release_date", "sections"]
}'

with_timeout() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  else
    perl -e 'alarm shift; exec @ARGV' "$seconds" "$@"
  fi
}

generate_changelog() {
  require_cmd claude
  [[ -f "$PROMPT_FILE" ]] || die "prompt file missing: $PROMPT_FILE"
  if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
    claude auth status --json 2>/dev/null | jq -e '.loggedIn' >/dev/null \
      || die "not authenticated — run 'claude auth login' or export ANTHROPIC_API_KEY"
  fi
  [[ -n "$(git log "$PREVIOUS_TAG..HEAD" --oneline -- "plugins/$PLUGIN/")" ]] \
    || die "no commits in plugins/$PLUGIN/ since $PREVIOUS_TAG — nothing to release"

  TODAY="$(date +%Y-%m-%d)"
  local prompt
  prompt="$(cat "$PROMPT_FILE")

<release_context>
plugin: $PLUGIN
previous_tag: $PREVIOUS_TAG
today: $TODAY
</release_context>"

  echo "[release] generating changelog for $PLUGIN since $PREVIOUS_TAG ..." >&2
  RESPONSE="$(with_timeout 180 claude -p "$prompt" \
    --model haiku \
    --permission-mode default \
    --tools "Bash,Read,Edit" \
    --allowed-tools "Bash(git log *)" "Edit(CHANGELOG.md)" \
    --disallowed-tools "Read(**/.env*)" "Read(**/*.pem)" "Read(**/*.key)" \
    --max-turns 10 \
    --max-budget-usd 0.50 \
    --no-session-persistence \
    --output-format json \
    --json-schema "$CHANGELOG_SCHEMA")" \
    || die "claude exited with an error or timed out"
}

expected_version() {
  local previous="$1" bump="$2" major minor patch
  IFS=. read -r major minor patch <<<"$previous"
  case "$bump" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "$major.$((minor + 1)).0" ;;
    patch) echo "$major.$minor.$((patch + 1))" ;;
  esac
}

validate_response() {
  local result_obj notes cost turns
  result_obj="$(jq -c 'if type == "array" then (map(select(.type == "result")) | last // {}) else . end' <<<"$RESPONSE")"
  cost="$(jq -r '.total_cost_usd // "n/a"' <<<"$result_obj")"
  turns="$(jq -r '.num_turns // "n/a"' <<<"$result_obj")"
  echo "[claude] cost=\$$cost turns=$turns" >&2

  if [[ "$(jq -r '.is_error // false' <<<"$result_obj")" == "true" ]]; then
    echo "$result_obj" | jq '{subtype, result, permission_denials}' >&2
    die "claude reported an error"
  fi

  notes="$(jq -c '.structured_output // (.result | fromjson? // empty)' <<<"$result_obj")"
  [[ -n "$notes" ]] || die "no structured output in claude response"
  echo "$notes" | jq . >&2

  local changed
  changed="$(git status --porcelain | awk '{print $2}')"
  if [[ "$(jq '.sections | length' <<<"$notes")" -eq 0 ]]; then
    [[ -z "$changed" ]] || die "empty sections but the working tree changed: $changed"
    die "no user-facing changes since $PREVIOUS_TAG — nothing to release"
  fi
  [[ "$changed" == "CHANGELOG.md" ]] || die "agent changed more than CHANGELOG.md: $changed"

  local bump="patch"
  jq -e '.sections | any(.title == "Added")' >/dev/null <<<"$notes" && bump="minor"
  jq -e '.sections | any(.title == "Breaking")' >/dev/null <<<"$notes" && bump="major"
  NEW_VERSION="$(jq -r '.version' <<<"$notes")"
  local expected
  expected="$(expected_version "${PREVIOUS_TAG#"$PLUGIN@"}" "$bump")"
  [[ "$NEW_VERSION" == "$expected" ]] || die "version $NEW_VERSION does not match a $bump bump from $PREVIOUS_TAG (expected $expected)"
  [[ "$(jq -r '.release_date' <<<"$notes")" == "$TODAY" ]] || die "release_date is not $TODAY"

  local added
  added="$(git diff -U0 -- CHANGELOG.md | grep '^+' | grep -v '^+++' | cut -c2-)"
  grep -qxF "### [$NEW_VERSION] — $TODAY" <<<"$added" || die "CHANGELOG.md has no '### [$NEW_VERSION] — $TODAY' heading"
  while IFS= read -r title; do
    grep -qxF "#### $title" <<<"$added" || die "CHANGELOG.md has no '#### $title' section"
  done < <(jq -r '.sections[].title' <<<"$notes")
  while IFS= read -r item; do
    grep -qxF -- "- $item" <<<"$added" || die "bullet missing from CHANGELOG.md: $item"
  done < <(jq -r '.sections[].items[]' <<<"$notes")

  echo "[release] changelog for $PLUGIN $NEW_VERSION validated ($bump bump)" >&2
}

bump_and_open_pr() {
  local branch="release/$PLUGIN@$NEW_VERSION" tmp
  git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 && die "branch $branch already exists on origin"

  tmp="$(mktemp)"
  jq --arg v "$NEW_VERSION" '.version = $v' "$PLUGIN_JSON" >"$tmp" && mv "$tmp" "$PLUGIN_JSON"
  tmp="$(mktemp)"
  jq --arg p "$PLUGIN" --arg v "$NEW_VERSION" \
    '(.plugins[] | select(.name == $p) | .version) = $v' "$MARKETPLACE_JSON" >"$tmp" && mv "$tmp" "$MARKETPLACE_JSON"

  local entry
  entry="$(git diff -U0 -- CHANGELOG.md | grep '^+' | grep -v '^+++' | cut -c2-)"

  git switch --quiet -c "$branch"
  git add CHANGELOG.md "$PLUGIN_JSON" "$MARKETPLACE_JSON"
  git commit --quiet -m "chore(release): $PLUGIN@$NEW_VERSION"
  git push --quiet -u origin "$branch"

  gh pr create --base main --head "$branch" \
    --title "chore(release): $PLUGIN@$NEW_VERSION" \
    --body "Release \`$PLUGIN@$NEW_VERSION\`. After merge, run \`bin/release.sh tag $PLUGIN\` on main.

$entry"

  echo "[release] PR opened. When CI is green and the PR is merged:" >&2
  echo "          git switch main && git pull && bin/release.sh tag $PLUGIN" >&2
}

tag_release() {
  local version tag
  version="$(jq -r --arg p "$PLUGIN" '.plugins[] | select(.name == $p) | .version' "$MARKETPLACE_JSON")"
  [[ "$version" == "$(jq -r '.version' "$PLUGIN_JSON")" ]] \
    || die "version mismatch between $MARKETPLACE_JSON and $PLUGIN_JSON"
  tag="$PLUGIN@$version"
  git rev-parse -q --verify "refs/tags/$tag" >/dev/null && die "$tag already exists — merge a release PR first"
  grep -qF "### [$version] — " CHANGELOG.md || die "CHANGELOG.md has no entry for $version"

  git tag -a "$tag" -m "$PLUGIN $version"
  git push --quiet origin "$tag"
  echo "[release] tagged and pushed $tag" >&2
}

case "$MODE" in
  prepare)
    generate_changelog
    validate_response
    bump_and_open_pr
    ;;
  tag)
    tag_release
    ;;
esac
