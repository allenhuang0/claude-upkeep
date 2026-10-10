---
name: upkeep
description: >
  Update the whole Claude Code ecosystem in one go: CLI, plugin marketplaces
  and plugins, agent skills (npx skills), npm globals, Homebrew, MCP servers
  (npx cache + git checkouts), uv tools and Rust/Bun toolchains. Python envs
  and macOS updates are reported, never applied. Use when the user says
  "update all" or wants everything current.
disable-model-invocation: true
---

# /upkeep — Update Everything

Three phases, in order. **Never ask for confirmation.** Every update is
independent: when one fails, record the reason and carry on. For each
component record **old, new, status, note**. Status is one of `updated`,
`latest`, `failed`, `skipped`, `report only`.

---

## Phase 1: Scan

Read `<this skill's base directory>/../check/SKILL.md` (the base directory
is shown when the skill loads) and run its **Scan** section exactly — same
parallel steps, same recorded fields. `SCRIPTS` there resolves to
`<this skill's base directory>/../../scripts`. Do not print its report.

---

## Phase 2: Update

Run the steps below as **parallel Bash calls**, with two ordering rules:
- 2a must finish before 2b (plugins update from the refreshed marketplaces).
- 2k (CLI) runs last, after every `claude plugin` command has finished.

Act only on components Phase 1 found outdated, except 2a/2b which always run.

### 2a. Marketplaces

```bash
claude plugin marketplace update
```

Each marketplace row: `updated` (note: new commits pulled) or `latest`.

### 2b. Plugins

Run **sequentially** in one Bash call — concurrent runs race on
`installed_plugins.json`. For each plugin entry recorded in Phase 1:

```bash
claude plugin update <id> -s user                              # scope user
(cd <projectPath> && claude plugin update <id> -s <scope>)     # scope project / local
```

Then re-read `~/.claude/plugins/installed_plugins.json` and compare each
entry's `version` and `gitCommitSha` with Phase 1: changed → `updated`,
unchanged → `latest`, non-zero exit → `failed`.

### 2c. Agent skills

If any skill is `outdated`:

```bash
npx -y skills update -g -y 2>&1
```

Then re-run `bash "$SCRIPTS/scan-skills.sh"` to set each skill's final
status. Skills still `gone upstream` stay as rows — the CLI never deletes
them non-interactively. Note: this command also re-links every lock-file
skill into the agent skill folders.

### 2d. npm globals

```bash
npm install -g <pkg1>@latest <pkg2>@latest ...
```

`@latest` (not `npm update`) so major versions are included. Verify with
`npm ls -g --depth=0 --json`.

### 2e. Homebrew

```bash
brew upgrade --formula <formula1> <formula2> ...
brew upgrade --cask <cask1> <cask2> ... </dev/null
```

Leave `pinned` items alone (`skipped`). Afterwards run
`brew outdated --json=v2`: anything still listed is `failed`. A cask that
needs `sudo` fails fast without a terminal → note
`needs sudo — run brew upgrade --cask <name> yourself`.

### 2f. MCP servers — npx

For each `MCP (npx)` row with status `outdated`, delete its stale npx cache
directory (the row's **path**, always under `~/.npm/_npx/`). It is cache
only; npx downloads the latest version on the next launch.

```bash
rm -rf "<path>"
```

Status `updated`, new = the latest version, note `applies on next launch`.

### 2g. MCP servers — git checkouts

For each `MCP (git)` row with status `outdated`:
- note contains `local changes` → `skipped`, note `local changes — pull manually`.
- otherwise, in the repo root (the row's **path**):

```bash
git -C "<path>" pull --ff-only
```

then rebuild by what the repo contains, first match only:

| Repo contains | Rebuild |
|---|---|
| `uv.lock` | `(cd "<path>" && uv sync)` |
| `package.json` | `(cd "<path>" && npm install && if jq -e '.scripts.build' package.json >/dev/null; then npm run build; fi)` |
| `requirements.txt` + `.venv/` | `"<path>/.venv/bin/pip" install -r "<path>/requirements.txt"` |

New = `git -C "<path>" rev-parse --short HEAD`. Pull refused (diverged) or
rebuild error → `failed` with a one-line reason.

### 2h. uv tools

```bash
uv tool upgrade <tool1> <tool2> ...
```

Verify with `uv tool list`.

### 2i. Toolchains

```bash
rustup update        # if rustup reported updates
bun upgrade          # if bun is outdated
```

### 2j. Report-only items

`python env` and `macOS` rows are never changed. Carry them over with
status `report only`.

### 2k. Claude Code CLI

If outdated:

```bash
claude update
claude --version
```

---

## Phase 3: Report

Output **exactly** this format:

```
## Update Report

| Component | Type | Old | New | Status | Note |
|-----------|------|-----|-----|--------|------|
| <name> | <type> | <old> | <new> | <status> | <note> |

**Summary:** X updated · Y failed · Z skipped · W report only · V already latest
```

Rules:
- One row per component whose final status is **not** `latest`; already
  latest ones are counted in the summary only.
- Order rows by type, in the Phase 2 order.
- `failed` rows: New = `—`, Note = the short error.
- `git` versions are short commit hashes.

Then add only the notes that apply:
- Plugins updated → `> Run /reload-plugins to apply plugin updates.`
- MCP servers updated → `> Restart Claude Code (or reconnect in /mcp) to load the new MCP servers.`
- CLI updated → `> Restart Claude Code to apply the CLI update.`
- `gone upstream` skills → `> Removed upstream: <names>. Remove with npx skills remove -g <name>.`
- `python env` rows → `> Python environments are never upgraded automatically. Upgrade deliberately, e.g. conda update -n <env> --all.`
- `macOS` rows → `> macOS updates pending: install from System Settings → Software Update.`

If Phase 1 found nothing outdated and nothing report-only, output instead:

```
## Update Report

Everything is up to date. No updates available.
```
