<p align="center">
  <h1 align="center">claude-upkeep</h1>
  <p align="center"><strong>One command to update your entire Claude Code ecosystem</strong></p>
  <p align="center">Plugins &middot; npm &middot; Homebrew &middot; MCP Servers &middot; CLI &mdash; all in sync</p>
  <p align="center">
    <a href="#quick-start">Quick Start</a> |
    <a href="#features">Features</a> |
    <a href="#commands">Commands</a> |
    <a href="#faq">FAQ</a>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/Claude_Code-Plugin-blue?style=flat-square" alt="Claude Code Plugin" />
    <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License MIT" />
    <img src="https://img.shields.io/badge/Dependencies-Zero-brightgreen?style=flat-square" alt="Zero Dependencies" />
    <img src="https://img.shields.io/badge/PRs-Welcome-orange?style=flat-square" alt="PRs Welcome" />
  </p>
</p>

---

## Why claude-upkeep?

Claude Code's power comes from its ecosystem — plugins, MCP servers, npm tools, Homebrew packages, and the CLI itself. But keeping everything up to date means remembering six different commands with six different syntaxes, scattered across six different package managers. Miss one and you're debugging stale versions instead of shipping code.

**claude-upkeep** collapses all of that into a single slash command.

**Before:** 6 different commands, each with its own syntax, each easy to forget.

```
claude plugins update
npm update -g @anthropic-ai/claude-code
brew upgrade
cd ~/.claude/mcp-servers/foo && git pull
pip install --upgrade bar-mcp
# ...did I miss one?
```

**After:** Just `/upkeep`.

---

## Features

- 🔄 **One-command updates** — plugins, npm globals, Homebrew packages, MCP servers, and CLI, all at once
- 🔍 **Safe mode** — run `/upkeep:check` to preview every available update before committing to changes
- 📊 **Structured reports** — Markdown tables with version diffs so you see exactly what changed
- 🛡️ **Fault tolerant** — a single component failure never blocks the rest of your updates
- 🪶 **Zero dependencies** — pure SKILL.md implementation, no scripts or runtime needed

---

## Quick Start

**1. Add the marketplace**

```
/install-plugin marketplace add allenhuang0/claude-upkeep
```

**2. Install the plugin**

```
/install-plugin upkeep@claude-upkeep
```

**3. Reload plugins**

```
/reload-plugins
```

Then just run `/upkeep` and you're done.

---

## Commands

| Command | Description |
|---------|-------------|
| `/upkeep` | Auto-update all components and output a structured report |
| `/upkeep:check` | List available updates without making any changes |

---

## What Gets Updated

| Component | Detection | Update Method |
|-----------|-----------|---------------|
| Claude Code Plugins | `claude plugins list` | `claude plugins update` |
| npm Global Packages | `npm outdated -g` | `npm update -g` |
| Homebrew Packages | `brew outdated` | `brew upgrade` |
| Git MCP Servers | `git fetch` + log compare | `git pull` |
| pip MCP Servers | `pip index versions` | `pip install --upgrade` |
| Claude Code CLI | `npm view` vs `claude --version` | `npm update -g` |

---

## FAQ

<details>
<summary><strong>Will this break my environment?</strong></summary>
<br>

Each update runs independently. If one component fails, the rest continue normally. The final report shows you exactly what changed, what was skipped, and what failed — so you always know the state of your system.

</details>

<details>
<summary><strong>Does it support Linux?</strong></summary>
<br>

Currently optimized for macOS. Linux support is planned. Because claude-upkeep is a pure Skill (no compiled code or shell scripts), Claude adapts naturally to different environments — most components already work cross-platform.

</details>

<details>
<summary><strong>What about npm major version upgrades?</strong></summary>
<br>

`npm update -g` follows semver — it won't jump major versions unless the package's `latest` tag points there. If you're concerned, run `/upkeep:check` first to review what would change before applying updates.

</details>

<details>
<summary><strong>Do I need to restart after updating?</strong></summary>
<br>

Run `/reload-plugins` if any plugins were updated. Restart Claude Code only if the CLI itself was updated. The report tells you exactly what action is needed.

</details>

---

## Contributing

```bash
git clone https://github.com/allenhuang0/claude-upkeep.git
cd claude-upkeep
```

Validate your changes work as a Claude Code plugin, then open a PR. Contributions are welcome — whether it's new component support, better detection logic, or documentation improvements.

---

## License

[MIT](LICENSE)

---

<p align="center"><strong>claude-upkeep</strong> — keep your tools sharp</p>
