# claude-upkeep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin that updates all ecosystem components with a single command.

**Architecture:** Pure-Skill plugin — two `SKILL.md` files with detailed instructions for Claude to scan and update plugins, npm globals, brew packages, git/pip MCP servers, and CLI. No scripts, no runtime dependencies.

**Tech Stack:** Markdown (SKILL.md), JSON (plugin.json, marketplace.json)

---

### Task 1: Scaffold plugin structure

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `LICENSE`

- [ ] **Step 1: Create plugin manifest**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "upkeep",
  "description": "One-command update for your entire Claude Code ecosystem",
  "version": "1.0.0",
  "author": {
    "name": "Allen Huang"
  },
  "homepage": "https://github.com/allenhuang0/claude-upkeep",
  "repository": "https://github.com/allenhuang0/claude-upkeep",
  "license": "MIT",
  "keywords": ["update", "upgrade", "maintenance", "plugins", "mcp", "brew", "npm"]
}
```

- [ ] **Step 2: Create marketplace catalog**

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "claude-upkeep",
  "owner": {
    "name": "Allen Huang"
  },
  "metadata": {
    "description": "Keep your Claude Code ecosystem up to date with a single command"
  },
  "plugins": [
    {
      "name": "upkeep",
      "source": "./",
      "description": "One-command update for your entire Claude Code ecosystem"
    }
  ]
}
```

Note: version is managed in `plugin.json` only (per spec: avoid setting in both places).

- [ ] **Step 3: Create MIT LICENSE file**

Standard MIT license with "Allen Huang" and year 2026.

- [ ] **Step 4: Validate plugin structure**

Run: `claude plugin validate /tmp/claude-upkeep`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/ LICENSE
git commit -m "chore: scaffold plugin structure with manifest and marketplace"
```

---

### Task 2: Write `/upkeep` skill (auto mode)

**Files:**
- Create: `skills/upkeep/SKILL.md`

- [ ] **Step 1: Create the SKILL.md file**

Create `skills/upkeep/SKILL.md` with YAML frontmatter and comprehensive step-by-step instructions for Claude to:

1. **Scan all 6 component types** in parallel:
   - Plugins: `claude plugins list` to get names, then check each with `claude plugins update <name>@<marketplace>` (the update command itself reports if already latest)
   - npm globals: `npm outdated -g` to detect outdated packages
   - Brew: `brew outdated` to detect outdated packages
   - Git MCP servers: read `~/.claude/mcp.json`, identify git-based servers by checking if command path is inside a git repo (`git -C <dir> rev-parse`), then `git fetch` + compare
   - pip MCP servers: identify pip-installed servers (command path contains `.venv/bin/` or resolvable via `pip show`), compare installed vs latest with `pip index versions`
   - CLI: compare `claude --version` with `npm view @anthropic-ai/claude-code version`

2. **Execute all updates** — each independently, failures don't cascade:
   - `claude plugins update <name>@<marketplace>`
   - `npm update -g <pkg1> <pkg2> ...`
   - `brew upgrade <pkg1> <pkg2> ...`
   - `git -C <path> pull`
   - `pip install --upgrade <pkg>`
   - `npm update -g @anthropic-ai/claude-code`

3. **Output a Markdown report table** with columns: Component | Type | Old | New | Status
4. **Summary line**: X updated, Y already latest, Z failed
5. **Post-update reminder**: `/reload-plugins` if any plugins were updated

Key SKILL.md instructions:
- Use parallel Bash calls where possible for speed
- Parse `npm outdated -g` output to extract package names and versions
- For MCP server identification: read the JSON config, check each server's `command` field
- If a component fails, catch the error and continue — include failure reason in report
- Never prompt the user for confirmation (this is auto mode)

- [ ] **Step 2: Test locally**

Run: `claude --plugin-dir /tmp/claude-upkeep` then invoke `/upkeep:upkeep`
Verify: skill loads and Claude follows the instructions correctly

- [ ] **Step 3: Commit**

```bash
git add skills/upkeep/SKILL.md
git commit -m "feat: add /upkeep skill for auto-updating all components"
```

---

### Task 3: Write `/upkeep:check` skill (safe mode)

**Files:**
- Create: `skills/check/SKILL.md`

- [ ] **Step 1: Create the SKILL.md file**

Create `skills/check/SKILL.md` with YAML frontmatter and instructions that:

1. Run the exact same scanning/detection steps as `/upkeep`
2. Do NOT execute any updates
3. Output the same table format but with "Status" column showing "outdated" or "latest" only
4. End with: "Run `/upkeep` to update all components."

- [ ] **Step 2: Test locally**

Run: `claude --plugin-dir /tmp/claude-upkeep` then invoke `/upkeep:check`
Verify: only checks, no updates executed

- [ ] **Step 3: Commit**

```bash
git add skills/check/SKILL.md
git commit -m "feat: add /upkeep:check skill for safe-mode version checking"
```

---

### Task 4: Write README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README matching WeClaude style**

Structure (all English):

```markdown
<p align="center">
  <h1 align="center">claude-upkeep</h1>
  <p align="center"><strong>One command to update your entire Claude Code ecosystem</strong></p>
  <p align="center">
    Plugins · npm globals · Homebrew · MCP servers · CLI — all in sync
  </p>
  <p align="center">
    <a href="#quick-start">Quick Start</a> |
    <a href="#features">Features</a> |
    <a href="#commands">Commands</a> |
    <a href="#faq">FAQ</a>
  </p>
  <p align="center">
    shields: Claude Code | MIT | Zero Dependencies | PRs Welcome
  </p>
</p>
```

Sections:
1. **Why claude-upkeep?** — pain point paragraph + before/after comparison
2. **Features** — 5 bullet points with emoji
3. **Quick Start** — 3 commands: add marketplace, install, /upkeep
4. **Commands** — table with `/upkeep` and `/upkeep:check`
5. **What Gets Updated** — 6-row matrix table (component, detection, update method)
6. **FAQ** — 4 collapsible items (safety, Linux, npm major versions, restart)
7. **Contributing** — clone + validate instructions
8. **License** — MIT
9. Centered footer tagline

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with install guide and feature overview"
```

---

### Task 5: Add CHANGELOG.md and finalize

**Files:**
- Create: `CHANGELOG.md`

- [ ] **Step 1: Write CHANGELOG**

```markdown
# Changelog

## [1.0.0] - 2026-03-31

### Added
- `/upkeep` skill — auto-update all Claude Code ecosystem components
- `/upkeep:check` skill — check for updates without making changes
- Covers: plugins, npm globals, Homebrew, git MCP servers, pip MCP servers, CLI
- Structured Markdown report with update summary
```

- [ ] **Step 2: Final validation**

Run: `claude plugin validate /tmp/claude-upkeep`
Expected: No errors, all components discovered

- [ ] **Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: add CHANGELOG for v1.0.0"
```

---

### Task 6: Create GitHub repo and push

**Files:** None (git operations only)

- [ ] **Step 1: Create GitHub repo**

```bash
gh repo create allenhuang0/claude-upkeep --public --description "One-command update for your entire Claude Code ecosystem" --source /tmp/claude-upkeep
```

- [ ] **Step 2: Push develop branch**

```bash
cd /tmp/claude-upkeep
git push -u origin develop
```

- [ ] **Step 3: Create main branch and push**

```bash
git checkout -b main
git push -u origin main
```

- [ ] **Step 4: Set main as default branch**

```bash
gh repo edit allenhuang0/claude-upkeep --default-branch main
```

- [ ] **Step 5: Test installation end-to-end**

In a fresh Claude Code session:
```
/plugin marketplace add allenhuang0/claude-upkeep
/plugin install upkeep@claude-upkeep
/reload-plugins
/upkeep:check
```

Verify: skill loads and produces an update report.
