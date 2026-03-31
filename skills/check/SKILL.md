---
name: check
description: >
  Check for available updates across the Claude Code ecosystem without
  making changes. Lists outdated plugins, npm globals, Homebrew packages,
  MCP servers, and CLI version. Use when the user wants to see what
  needs updating before committing.
disable-model-invocation: true
---

# /upkeep:check — Check for Available Updates (Read-Only)

Scan the Claude Code ecosystem for outdated components. **DO NOT execute
any updates** — this skill is strictly read-only.

Initialize two counters: `outdated = 0`, `up_to_date = 0`.
Initialize an empty report table rows list.

---

## Scan Environment

Run the following detection commands. Use **parallel Bash tool calls** for
steps 1 through 6 — they are independent of each other.

### 1. Plugins

Run:

```bash
claude plugins list
```

Parse the output to extract each installed plugin's identifier in the form
`<name>@<marketplace>`. Record every identifier.

If the command fails or returns no plugins, record that zero plugins are
installed and move on.

For each plugin, run:

```bash
claude plugins update --dry-run <name>@<marketplace> 2>/dev/null || true
```

If dry-run is not supported, record the plugin as `up to date` (cannot
determine remote version). If the output indicates an update is available,
record it as `outdated` with the current and latest versions.

### 2. npm Global Packages

Run:

```bash
npm outdated -g 2>/dev/null || true
```

**Note:** `npm outdated -g` exits with code 1 when outdated packages exist.
That is normal — not an error. The `|| true` prevents it from being treated
as a failure.

The output is a table with columns: Package, Current, Wanted, Latest, Location.
Extract each row's **Package**, **Current**, and **Latest** values. A package
is outdated when Current differs from Latest.

If the output is empty, all npm globals are up to date — there is nothing to
record for this category.

### 3. Homebrew Packages

Run:

```bash
brew outdated --verbose 2>/dev/null || true
```

Each line of output is an outdated package with version info. Extract the
package names, current versions, and available versions. If the output is
empty, everything is current.

### 4. Git-Based MCP Servers

Read the file `~/.claude/mcp.json`. If it does not exist, skip this step.

Parse the JSON. For each server entry, extract the `command` field. Resolve
the directory containing that command binary (use `dirname` on the path, or
for commands like `node`, look at the `args` array for a script path and use
its parent directory).

For each candidate directory, test if it is inside a git repository:

```bash
git -C <dir> rev-parse --is-inside-work-tree 2>/dev/null
```

If yes, get the repo root:

```bash
git -C <dir> rev-parse --show-toplevel
```

Then fetch and check for updates. Try `origin/main` first, fall back to
`origin/master`:

```bash
git -C <repo-path> fetch origin 2>/dev/null
git -C <repo-path> log HEAD..origin/main --oneline 2>/dev/null || \
  git -C <repo-path> log HEAD..origin/master --oneline 2>/dev/null
```

If the log output is non-empty, updates are available. Record the server
name (from mcp.json key), current short HEAD commit, and mark as `outdated`.
If the log is empty, the server is `up to date` — record the current HEAD.

### 5. pip-Based MCP Servers

From `~/.claude/mcp.json` (already read in step 4 — reuse the data), identify
servers whose `command` path contains `.venv/bin/` or whose command resolves
to a pip-installed package.

For each candidate, derive the package name:
- If the command path contains `.venv/bin/<name>`, the package name is `<name>`.
- Alternatively, use the server name from the mcp.json key as a hint.

Check installed vs latest version:

```bash
pip show <package-name> 2>/dev/null | grep -i '^Version:'
pip index versions <package-name> 2>/dev/null | head -1
```

If `pip show` fails, try using the venv's pip directly:

```bash
<venv-path>/bin/pip show <package-name> 2>/dev/null | grep -i '^Version:'
```

Compare the installed version to the latest. If they differ, mark as
`outdated`. If commands fail (package not on PyPI, etc.), skip that server.

### 6. Claude Code CLI

Run these two commands in the same Bash call:

```bash
claude --version 2>/dev/null
npm view @anthropic-ai/claude-code version 2>/dev/null
```

The first gives the installed version, the second gives the latest published
version. Compare them. If they differ, the CLI is outdated.

---

## Output Report

After all scans complete, output a Markdown report in **exactly** this
format:

```
## Update Check

| Component | Type | Current | Latest | Status |
|-----------|------|---------|--------|--------|
| <name> | <type> | <current> | <latest> | <status> |
...

**Summary:** X outdated, Y up to date

> Run `/upkeep` to update all components.
```

Rules for the table:
- Include **every** component discovered during scanning, whether outdated
  or not.
- **Type** is one of: `plugin`, `npm`, `brew`, `git MCP`, `pip MCP`, `CLI`.
- **Status** is one of: `outdated`, `up to date`.
- For `up to date` items: Current and Latest show the same version.
- For `outdated` items: Current shows installed version, Latest shows the
  available version.
- For git MCP servers, use short commit hashes as version identifiers.

After the table, output the **Summary** line with the two counters.

Then always append:
```
> Run `/upkeep` to update all components.
```

If **nothing was found at all** (no components detected), output instead:
```
## Update Check

No managed components detected. Nothing to check.
```

If **everything is up to date**, output instead:
```
## Update Check

| Component | Type | Current | Latest | Status |
|-----------|------|---------|--------|--------|
...

**Summary:** 0 outdated, Y up to date

Everything is up to date. No updates available.
```
