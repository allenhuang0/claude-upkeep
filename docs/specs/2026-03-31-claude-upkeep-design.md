# claude-upkeep — Design Spec

**Date:** 2026-03-31
**Author:** Allen Huang (`allenhuang0`)
**Status:** Approved

---

## Overview

`claude-upkeep` is a Claude Code plugin that provides a single-command update mechanism for the entire Claude Code ecosystem. It detects and updates all installed components — plugins, npm global packages, Homebrew packages, git-based MCP servers, pip-based MCP servers, and the Claude Code CLI itself.

**Problem:** Claude Code has no unified update command. Plugins, MCP servers, CLI tools, and package managers each require separate update workflows. Users must remember multiple commands and check multiple sources manually.

**Solution:** A pure-Skill plugin with two user-invocable skills:
- `/upkeep` — auto-update everything, output a report
- `/upkeep:check` — list available updates without making changes

## Architecture

### Approach: Pure Skill (no scripts, no MCP server)

All logic lives in `SKILL.md` files. Claude interprets the instructions and executes the appropriate shell commands via Bash. Zero runtime dependencies.

**Why this approach:**
- Simplest to install, maintain, and distribute
- No cross-platform script compatibility issues (Claude adapts)
- Zero dependencies beyond Claude Code itself
- Easiest for contributors to understand and modify

### Plugin Structure

```
claude-upkeep/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── skills/
│   ├── upkeep/
│   │   └── SKILL.md
│   └── check/
│       └── SKILL.md
├── README.md
├── LICENSE
└── CHANGELOG.md
```

## Components

### 1. Plugin Manifest (`.claude-plugin/plugin.json`)

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

### 2. Marketplace Catalog (`.claude-plugin/marketplace.json`)

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
      "description": "One-command update for your entire Claude Code ecosystem",
      "version": "1.0.0"
    }
  ]
}
```

### 3. Skill: `/upkeep` (Auto Mode — Default)

**File:** `skills/upkeep/SKILL.md`

**Frontmatter:**
```yaml
name: upkeep
description: >
  Auto-update all Claude Code ecosystem components — plugins, npm globals,
  Homebrew packages, git/pip MCP servers, and Claude Code CLI itself.
  Use when the user wants to update everything, keep tools current,
  or says "update all".
disable-model-invocation: true
```

**Execution Flow:**

1. **Scan environment** (parallel where possible):
   - Read `~/.claude/settings.json` → extract `enabledPlugins` list
   - Read `~/.claude/mcp.json` → identify MCP servers (git repos, brew, pip)
   - Run `npm outdated -g` → detect outdated npm global packages
   - Run `brew outdated` → detect outdated Homebrew packages
   - Run `claude plugins list` → get installed plugin names with `@marketplace` suffix
   - Check Claude Code CLI version vs `npm view @anthropic-ai/claude-code version`

2. **Execute updates** (parallel where possible, single failure does not block others):
   - `claude plugins update <name>@<marketplace>` for each plugin
   - `npm update -g <packages>` for outdated npm globals
   - `brew upgrade <packages>` for outdated Homebrew packages
   - `git -C <path> pull` for git-based MCP servers
   - `pip install --upgrade <pkg>` for pip-based MCP servers
   - `npm update -g @anthropic-ai/claude-code` for CLI itself

3. **Output report:**
   - Table: Component | Old Version | New Version | Status (updated/latest/failed)
   - Summary: X updated, Y already latest, Z failed
   - Post-update notes: remind about `/reload-plugins` or restart if needed

**Error handling:**
- Each component update is independent; failures don't cascade
- Failed items shown with error message in the report
- Network/permission issues get actionable suggestions

### 4. Skill: `/upkeep:check` (Safe Mode)

**File:** `skills/check/SKILL.md`

**Frontmatter:**
```yaml
name: check
description: >
  Check for available updates across the Claude Code ecosystem without
  making changes. Lists outdated plugins, npm globals, Homebrew packages,
  MCP servers, and CLI version. Use when the user wants to see what
  needs updating before committing.
disable-model-invocation: true
```

**Execution Flow:**
1. Same scanning steps as `/upkeep`
2. Output the same table but with no updates executed
3. Prompt: "Run `/upkeep` to update all components"

## Update Coverage Matrix

| Category | Detection Method | Update Method |
|----------|-----------------|---------------|
| Claude Code plugins | `claude plugins list` | `claude plugins update <name>@<marketplace>` |
| npm global packages | `npm outdated -g` | `npm update -g <packages>` |
| Homebrew packages | `brew outdated` | `brew upgrade <packages>` |
| Git-based MCP servers | `git fetch` + `git log HEAD..origin` | `git pull` |
| pip-based MCP servers | `pip index versions <pkg>` | `pip install --upgrade <pkg>` |
| Claude Code CLI | `npm view` vs `claude --version` | `npm update -g @anthropic-ai/claude-code` |

## Report Format

```
## Update Report

| Component | Type | Old | New | Status |
|-----------|------|-----|-----|--------|
| superpowers | plugin | 5.0.5 | 5.0.7 | updated |
| @openai/codex | npm | 0.113.0 | 0.118.0 | updated |
| xcodebuildmcp | brew | 2.0.7 | 2.3.2 | updated |
| kicad-mcp | git MCP | abc1234 | abc1234 | latest |
| spicebridge | pip MCP | 1.3.0 | 1.3.0 | latest |
| claude-code | CLI | 2.1.87 | 2.1.87 | latest |

**Summary:** 3 updated, 3 already latest, 0 failed

> Run `/reload-plugins` to apply plugin updates.
```

## README Design

English-only. Matches WeClaude style:
- Centered title + tagline + shields badges
- Navigation links
- Why section with pain point + solution
- Features with emoji bullets
- Quick Start (3 steps)
- Commands table
- What Gets Updated matrix
- Collapsible FAQ
- Contributing + License
- Centered footer

## Distribution

- GitHub repo: `allenhuang0/claude-upkeep`
- Marketplace name: `claude-upkeep`
- Install flow:
  ```
  /plugin marketplace add allenhuang0/claude-upkeep
  /plugin install upkeep@claude-upkeep
  /reload-plugins
  ```

## Future Considerations (Not in v1.0)

- Linux support (detect OS and adapt package managers)
- `--only` flag to update specific categories (e.g., `--only plugins,npm`)
- Scheduled auto-check via hooks (SessionStart reminder)
- Update history log
