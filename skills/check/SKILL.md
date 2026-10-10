---
name: check
description: >
  Read-only scan for available updates across the Claude Code ecosystem:
  CLI, plugin marketplaces, agent skills (npx skills), npm globals, Homebrew,
  MCP servers (npx + git), uv tools, Python/conda envs, Rust/Bun toolchains
  and macOS. Changes nothing. Use before /upkeep to preview what would change.
disable-model-invocation: true
---

# /upkeep:check — Scan for Updates (Read-Only)

**Never install, upgrade, pull, link or delete anything here.** The only
side effects allowed are metadata refreshes: `git fetch` (remote-tracking
refs only) and Homebrew's automatic index update.

`/upkeep` runs the **Scan** section of this file as its Phase 1, so record
exactly the fields each step names.

`SCRIPTS` below means `<this skill's base directory>/../../scripts` — the
base directory is shown when the skill loads. Both scripts need `jq`.

---

## Scan

Run steps 1–10 as **parallel Bash calls** — they are independent. When a
step's tool is not installed (`command -v` fails), skip the step silently.

For every component record: **name, type, current, latest, status, note**,
plus any extra field a step names.

### 1. Claude Code CLI — type `CLI`

```bash
claude --version 2>/dev/null; npm view @anthropic-ai/claude-code version 2>/dev/null
```

Outdated when the installed version differs from the published one.

### 2. Plugin marketplaces and plugins — type `marketplace`

```bash
jq -r 'to_entries[] | [.key, .value.installLocation, .value.lastUpdated] | @tsv' ~/.claude/plugins/known_marketplaces.json |
while IFS=$'\t' read -r name loc updated; do
  git -C "$loc" rev-parse --git-dir >/dev/null 2>&1 || { printf '%s\tnot git %s\n' "$name" "${updated%%T*}"; continue; }
  git -C "$loc" fetch -q 2>/dev/null || { printf '%s\tfetch failed\n' "$name"; continue; }
  printf '%s\t%s\n' "$name" "$(git -C "$loc" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo '?')"
done
jq -r '.plugins | to_entries[] | .key as $id | .value[]
       | [$id, .scope, .version, (.gitCommitSha // "-"), (.projectPath // "-")] | @tsv' \
  ~/.claude/plugins/installed_plugins.json
```

- A marketplace with N > 0 new commits is `outdated`, note `N new commits`.
  `fetch failed` → `unknown`.
- `not git <date>` (archive-installed marketplace, no commit count) →
  status `unknown`, note `last refreshed <date>`.
- Record every installed plugin as **id, scope, version, gitCommitSha,
  projectPath** — `/upkeep` needs them. In this check, plugins are not
  reported one by one: name the installed plugins of an outdated
  marketplace in its note.

### 3. Agent skills (`npx skills`) — type `skill`

```bash
bash "$SCRIPTS/scan-skills.sh"
```

TSV columns: name, source, status, local_ref, remote_ref. Status is
`up to date`, `outdated`, `gone upstream` or `unknown`. No output means no
skills are installed this way. Do **not** use `npx skills check` — it
applies updates.

### 4. npm global packages — type `npm`

```bash
npm outdated -g --json 2>/dev/null || true
npm ls -g --depth=0 --json 2>/dev/null | jq '.dependencies | length'
```

`npm outdated` exits 1 when something is outdated — normal. Each key is a
package with `current` and `latest`. Skip `@anthropic-ai/claude-code`
(step 1 covers it). The second line is the total, for the summary count.

### 5. Homebrew — type `brew`

```bash
brew outdated --json=v2 2>/dev/null
```

Read `.formulae[]` and `.casks[]`: current = last of
`installed_versions`, latest = `current_version`. Record whether each item
is a cask (needed by `/upkeep`). `pinned: true` → status `pinned`.

### 6. MCP servers — type `MCP (npx)` or `MCP (git)`

```bash
bash "$SCRIPTS/scan-mcp.sh"
```

TSV columns: name, kind, target, current, latest, status, note, path.
Reads user- and project-scope servers from `~/.claude.json`. Keep **note**
and **path** — `/upkeep` needs them. Status `auto` (resolves `@latest` on
every launch) counts as up to date.

### 7. uv tools — type `uv tool`

```bash
uv tool list --outdated 2>/dev/null
```

Each tool line reads `<name> v<current> [latest: <latest>]`; lines starting
with `- ` are its executables (ignore). Every listed tool is outdated. MCP
servers installed as uv tools show up here.

### 8. Python / conda environments — type `python env` (report only)

```bash
for p in $(conda env list --json 2>/dev/null | jq -r '.envs[]'); do
  printf '%s\t%s\n' "$p" "$("$p/bin/python" -m pip list --outdated --format=json 2>/dev/null | jq length)" &
done; wait
```

One row per environment: name = env directory name (`base` for the conda
root), current = `N packages outdated`, status `report only` when N > 0.
Upgrading a whole environment can break it, so upkeep never does.

### 9. Toolchains — type `toolchain`

```bash
command -v rustup >/dev/null && rustup check 2>/dev/null
b=$(command -v bun) && case "$b" in "$(brew --prefix 2>/dev/null)"/*) ;; *) echo "bun $(bun --version) $(npm view bun version 2>/dev/null)";; esac
```

`rustup check` prints `<toolchain> - update available : A -> B` for each
outdated item. Bun is checked only when it is not Homebrew-managed (step 5
covers that case).

### 10. macOS — type `macOS` (report only)

```bash
softwareupdate -l 2>&1
```

Each `* Label: <name>` is a pending update → status `report only`.
These may need a restart, so upkeep never installs them.

---

## Report

Output **exactly** this format:

```
## Update Check

| Component | Type | Current | Latest | Status | Note |
|-----------|------|---------|--------|--------|------|
| <name> | <type> | <current> | <latest> | <status> | <note> |

**Summary:** X outdated · Y report only · Z up to date (<n> skill, <n> npm, …)

> Run `/upkeep` to apply updates.
```

Rules:
- List every component that is **not** up to date; count up-to-date ones in
  the summary only, broken down by type.
- Order rows by step (CLI first, macOS last).
- `gone upstream` skill → note `removed or moved upstream — npx skills remove -g <name>`.
- `MCP (git)` with `local changes` in its note → append `/upkeep will skip it`.
- If nothing is outdated, replace the table with
  `Everything is up to date.` and still list any `report only` rows.
