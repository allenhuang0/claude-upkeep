---
name: upkeep
description: >
  Auto-update all Claude Code ecosystem components — plugins, npm globals,
  Homebrew packages, git/pip MCP servers, and Claude Code CLI itself.
  Use when the user wants to update everything, keep tools current,
  or says "update all".
disable-model-invocation: true
---

# /upkeep — Auto-Update All Components

Follow the three phases below in order. Track every component you discover
so you can build the final report.

Initialize three counters: `updated = 0`, `latest = 0`, `failed = 0`.
Initialize an empty report table rows list.

---

## Phase 1: Scan Environment

Run the following detection commands. Use **parallel Bash tool calls** for
steps 1 through 6 — they are independent of each other.

### 1. Plugins

Run:

```bash
claude plugins list
```

Parse the output to extract each installed plugin's identifier in the form
`<name>@<marketplace>`. Record every identifier for Phase 2.

If the command fails or returns no plugins, record that zero plugins are
installed and move on.

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

If the output is empty, all npm globals are up to date.

### 3. Homebrew Packages

Run:

```bash
brew outdated 2>/dev/null || true
```

Each line of output is an outdated package name (possibly with version info
after a space). Extract the package names. If the output is empty, everything
is current.

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

If the log output is non-empty, updates are available. Record the repo path,
the server name (from mcp.json key), the current short HEAD commit, and the
remote branch name.

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

Compare the installed version to the latest. If they differ, mark as outdated.
If commands fail (package not on PyPI, etc.), skip that server.

### 6. Claude Code CLI

Run these two commands in the same Bash call:

```bash
claude --version 2>/dev/null
npm view @anthropic-ai/claude-code version 2>/dev/null
```

The first gives the installed version, the second gives the latest published
version. Compare them. If they differ, the CLI is outdated.

---

## Phase 2: Execute Updates

Execute ALL updates below. Each update is independent — if one fails, record
the error and continue with the rest. **Never prompt the user for
confirmation.** Use **parallel Bash tool calls** for independent updates.

For each update, record the before-version, after-version, and status.

### 1. Plugins

For each plugin identifier from Phase 1, run:

```bash
claude plugins update <name>@<marketplace>
```

Parse the output to determine if the plugin was updated or was already at the
latest version. Record the old and new version if shown, or "latest" if
already current.

If the command fails, record status as "failed" with the error message.

### 2. npm Global Packages

If there are outdated npm packages from Phase 1, batch them into one command:

```bash
npm update -g <package1> <package2> ...
```

After the command completes, verify by running `npm list -g <package> --depth=0`
for each package to get the new version. Record old (from Phase 1) and new
versions.

If the update command fails, record status as "failed".

### 3. Homebrew Packages

If there are outdated brew packages from Phase 1, batch them:

```bash
brew upgrade <package1> <package2> ...
```

After the command completes, get new versions with `brew list --versions <pkg>`
for each package. Record old and new versions.

If the upgrade fails for any package, record that package as "failed".

### 4. Git-Based MCP Servers

For each git repo with available updates from Phase 1, run:

```bash
git -C <repo-path> pull
```

After pull, get the new HEAD:

```bash
git -C <repo-path> rev-parse --short HEAD
```

Record old commit (from Phase 1) and new commit. If pull fails, record as
"failed".

### 5. pip-Based MCP Servers

For each outdated pip package from Phase 1, run:

```bash
pip install --upgrade <package-name>
```

Or if using a venv:

```bash
<venv-path>/bin/pip install --upgrade <package-name>
```

After install, verify the new version with `pip show <package-name>`. Record
old and new versions.

### 6. Claude Code CLI

Only if the CLI was outdated in Phase 1, run:

```bash
npm update -g @anthropic-ai/claude-code
```

Verify by running `claude --version` after update. Record old and new versions.

---

## Phase 3: Output Report

After all updates complete, output a Markdown report in **exactly** this
format:

```
## Update Report

| Component | Type | Old | New | Status |
|-----------|------|-----|-----|--------|
| <name> | <type> | <old-version> | <new-version> | <status> |
...

**Summary:** X updated, Y already latest, Z failed
```

Rules for the table:
- Include **every** component discovered in Phase 1, whether updated or not.
- **Type** is one of: `plugin`, `npm`, `brew`, `git MCP`, `pip MCP`, `CLI`.
- **Status** is one of: `updated`, `latest`, `failed`.
- For `updated` items: Old = previous version, New = current version.
- For `latest` items: Old and New show the same (current) version.
- For `failed` items: New = the error reason (keep it short, one line).
- For git MCP servers, use short commit hashes as version identifiers.

After the table, output the **Summary** line with the three counters.

Then, conditionally add these notes:

- If **any plugins were updated**, append:
  ```
  > Run `/reload-plugins` to apply plugin updates.
  ```

- If the **CLI was updated**, append:
  ```
  > Restart Claude Code to apply CLI updates.
  ```

- If **nothing was outdated**, output instead:
  ```
  ## Update Report

  Everything is up to date. No updates available.
  ```
