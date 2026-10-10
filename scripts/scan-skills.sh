#!/usr/bin/env bash
# Read-only update check for agent skills installed with `npx skills`.
#
# `npx skills` has no read-only check (its `check` command now applies
# updates), so this compares the lock file against GitHub. Nothing on disk
# is modified.
#   - Skill in a sub-folder: lock `skillFolderHash` vs the folder's git tree SHA.
#   - Skill at the repo root: the lock hash is not the repo tree SHA, so the
#     latest commit date is compared with the lock `updatedAt` instead.
#
# Output: one TSV line per skill:
#   name <TAB> source <TAB> status <TAB> local_ref <TAB> remote_ref
# status is one of: up to date | outdated | gone upstream | unknown
#
# Requires jq. Uses `gh api` when gh is logged in, else unauthenticated curl
# (60 requests/hour). Override the lock path with SKILLS_LOCK.
set -uo pipefail

LOCK="${SKILLS_LOCK:-$HOME/.agents/.skill-lock.json}"
[ -f "$LOCK" ] || exit 0
command -v jq >/dev/null || { echo "scan-skills: jq is required" >&2; exit 2; }

USE_GH=0
if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  USE_GH=1
fi

CACHE=$(mktemp -d)
trap 'rm -rf "$CACHE"' EXIT

# Fetch a GitHub API path once per run and print the body.
# Returns 4 on HTTP 404, 1 on any other failure.
github_get() {
  local key code=""
  key="$CACHE/$(printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_')"
  if [ ! -f "$key" ]; then
    if [ "$USE_GH" = 1 ]; then
      if ! gh api "$1" >"$key" 2>"$key.err"; then
        if grep -q 'HTTP 404' "$key.err"; then code=404; else code=err; fi
      fi
    else
      code=$(curl -sSL -o "$key" -w '%{http_code}' \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/$1" 2>/dev/null) || code=err
      [ "$code" = 200 ] && code=""
    fi
    if [ -n "$code" ]; then
      rm -f "$key"
      [ "$code" = 404 ] && return 4
      return 1
    fi
  fi
  cat "$key"
}

# Print "<status>\t<remote_ref>" for a skill whose SKILL.md is at the repo root.
check_root_skill() {
  local src="$1" updated="$2" body rc date
  body=$(github_get "repos/$src/commits/HEAD"); rc=$?
  [ "$rc" = 4 ] && { printf 'gone upstream\t-'; return; }
  [ "$rc" != 0 ] && { printf 'unknown\t-'; return; }
  date=$(jq -r '.commit.committer.date // empty' <<<"$body")
  if [ -z "$date" ]; then
    printf 'unknown\t-'
  elif [[ "$date" > "$updated" ]]; then
    printf 'outdated\t%s' "$(jq -r '.sha[0:7]' <<<"$body")"
  else
    printf 'up to date\t%s' "$(jq -r '.sha[0:7]' <<<"$body")"
  fi
}

# Print "<status>\t<remote_ref>" for a skill living in a sub-folder.
check_folder_skill() {
  local src="$1" dir="$2" hash="$3" parent name body rc remote
  parent=$(dirname "$dir")
  [ "$parent" = "." ] && parent=""
  name=$(basename "$dir")
  body=$(github_get "repos/$src/contents/$parent"); rc=$?
  [ "$rc" = 4 ] && { printf 'gone upstream\t-'; return; }
  [ "$rc" != 0 ] && { printf 'unknown\t-'; return; }
  remote=$(jq -r --arg n "$name" \
    '.[]? | select(.name == $n and .type == "dir") | .sha' <<<"$body")
  if [ -z "$remote" ]; then
    printf 'gone upstream\t-'
  elif [ "$remote" = "$hash" ]; then
    printf 'up to date\t%s' "${remote:0:7}"
  else
    printf 'outdated\t%s' "${remote:0:7}"
  fi
}

jq -r '.skills | to_entries[]
       | [.key, .value.source, .value.sourceType, .value.skillPath,
          .value.skillFolderHash, .value.updatedAt]
       | @tsv' "$LOCK" |
while IFS=$'\t' read -r name src type path hash updated; do
  if [ "$type" != "github" ]; then
    result=$'unknown\t-'
  elif [ "$(dirname "$path")" = "." ]; then
    result=$(check_root_skill "$src" "$updated")
  else
    result=$(check_folder_skill "$src" "$(dirname "$path")" "$hash")
  fi
  status=${result%%$'\t'*}
  remote=${result#*$'\t'}
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$src" "$status" "${hash:0:7}" "$remote"
done
