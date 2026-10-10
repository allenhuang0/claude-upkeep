#!/usr/bin/env bash
# Read-only update check for Claude Code MCP servers.
#
# Reads user- and project-scope servers from ~/.claude.json (override with
# CLAUDE_JSON). Two kinds are checked:
#   npx  - `npx [-y] <pkg>`: version in the npx cache vs `npm view <pkg> version`
#   git  - server launched from a local git checkout (`--directory <dir>`,
#          an absolute command path, or an absolute script argument)
# Other servers (remote http/sse, uv tools, standalone scripts) are not listed;
# uv tools are covered by `uv tool list --outdated`.
# `git fetch` only moves remote-tracking refs; working trees are untouched.
#
# Output: one TSV line per server:
#   name kind target current latest status note path
# status: up to date | outdated | auto | pinned | not cached | no upstream | unknown
# path:   npx cache dir (npx) or repo root (git)
set -uo pipefail

CONFIG="${CLAUDE_JSON:-$HOME/.claude.json}"
[ -f "$CONFIG" ] || exit 0
command -v jq >/dev/null || { echo "scan-mcp: jq is required" >&2; exit 2; }

row() {
  local IFS=$'\t'
  printf '%s\n' "$*"
}

npx_row() {
  local name="$1" spec="$2" pkg="$2" ver="" f p cur latest status cache=""
  case "$spec" in
    @*/*@* | [!@]*@*) pkg=${spec%@*}; ver=${spec##*@} ;;
  esac
  if [ "$ver" = "latest" ]; then
    row "$name" npx "$pkg" - - auto "@latest is resolved on every launch" -
    return
  elif [ -n "$ver" ]; then
    row "$name" npx "$pkg" "$ver" - pinned "version pinned in config" -
    return
  fi
  # Newest npx cache entry holding this package, if any.
  f=""
  for p in "$HOME"/.npm/_npx/*/node_modules/"$pkg"/package.json; do
    if [ -f "$p" ] && { [ -z "$f" ] || [ "$p" -nt "$f" ]; }; then f="$p"; fi
  done
  cur="-"
  if [ -n "$f" ]; then
    cur=$(jq -r '.version' "$f")
    cache=${f%/node_modules/*}
  fi
  latest=$(npm view "$pkg" version 2>/dev/null || echo -)
  if [ -z "$f" ]; then status="not cached"
  elif [ "$latest" = "-" ]; then status="unknown"
  elif [ "$cur" = "$latest" ]; then status="up to date"
  else status="outdated"
  fi
  row "$name" npx "$pkg" "$cur" "$latest" "$status" - "${cache:--}"
}

git_row() {
  local name="$1" top="$2" cur latest status note="" behind
  git -C "$top" fetch -q 2>/dev/null || note="fetch failed"
  cur=$(git -C "$top" rev-parse --short HEAD 2>/dev/null || echo -)
  if ! latest=$(git -C "$top" rev-parse --short '@{u}' 2>/dev/null); then
    latest="-"; status="no upstream"
  else
    behind=$(git -C "$top" rev-list --count 'HEAD..@{u}')
    if [ "$behind" -gt 0 ]; then
      status="outdated"; note="$behind commits behind${note:+; $note}"
    elif [ -n "$note" ]; then
      status="unknown"
    else
      status="up to date"
    fi
  fi
  if [ -n "$(git -C "$top" status --porcelain --untracked-files=no 2>/dev/null)" ]; then
    note="${note:+$note; }local changes"
  fi
  row "$name" git "$(basename "$top")" "$cur" "$latest" "$status" "${note:--}" "$top"
}

# One record per distinct server: name, command, npx spec, --directory value,
# first absolute-path argument. \x1f keeps empty fields from collapsing.
jq -r '
  [(.mcpServers // {} | to_entries[]),
   (.projects // {} | .[] | .mcpServers // {} | to_entries[])]
  | unique_by([.key, .value.command, .value.args]) | .[]
  | (.value.args // []) as $a | (.value.command // "") as $c
  | [ .key, $c,
      (if ($c | test("(^|/)npx$")) then
         (($a | index("-p")) // ($a | index("--package"))) as $i
         | if $i then $a[$i + 1] else ([$a[] | select(startswith("-") | not)][0] // "") end
       else "" end),
      ((($a | index("--directory")) // ($a | index("--project"))) as $i
         | if $i then $a[$i + 1] else "" end),
      ([$a[] | select(startswith("/"))][0] // "")
    ] | join("\u001f")' "$CONFIG" |
while IFS=$'\x1f' read -r name cmd spec dirarg absarg; do
  if [ -n "$spec" ]; then
    npx_row "$name" "$spec"
    continue
  fi
  dir="$dirarg"
  [ -z "$dir" ] && [ "${cmd:0:1}" = "/" ] && dir=$(dirname "$cmd")
  if [ -z "$dir" ] && [ -n "$absarg" ]; then
    if [ -d "$absarg" ]; then dir="$absarg"; else dir=$(dirname "$absarg"); fi
  fi
  [ -n "$dir" ] && [ -d "$dir" ] || continue
  top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || continue
  git_row "$name" "$top"
done
