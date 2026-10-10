<p align="center">
  <h1 align="center">claude-upkeep</h1>
  <p align="center"><strong>One command to update your entire Claude Code ecosystem</strong></p>
  <p align="center">Plugins &middot; Skills &middot; npm &middot; Homebrew &middot; MCP Servers &middot; uv &middot; CLI &mdash; all in sync</p>
  <p align="center">
    <a href="#quick-start">Quick Start</a> |
    <a href="#features">Features</a> |
    <a href="#commands">Commands</a> |
    <a href="#faq">FAQ</a>
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/Claude_Code-Plugin-blue?style=flat-square" alt="Claude Code Plugin" />
    <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License MIT" />
    <img src="https://img.shields.io/badge/Requires-jq-brightgreen?style=flat-square" alt="Requires jq" />
    <img src="https://img.shields.io/badge/PRs-Welcome-orange?style=flat-square" alt="PRs Welcome" />
  </p>
</p>

---

## Why claude-upkeep?

Claude Code's power comes from its ecosystem — plugins, agent skills, MCP servers, npm tools, Homebrew packages, uv tools, and the CLI itself. But keeping everything up to date means remembering a dozen commands scattered across as many package managers. Miss one and you're debugging stale versions instead of shipping code.

**claude-upkeep** collapses all of that into a single slash command.

**Before:** a dozen commands, each with its own syntax, each easy to forget.

```
claude plugin marketplace update && claude plugin update <each plugin>
npx skills update -g
npm install -g <pkg>@latest
brew upgrade
cd ~/mcp-servers/foo && git pull && uv sync
uv tool upgrade --all
rustup update
claude update
# ...did I miss one?
```

**After:** Just `/upkeep`.

---

## Features

- 🔄 **One-command updates** — marketplaces, plugins, agent skills, npm globals, Homebrew, MCP servers, uv tools, toolchains, and the CLI, all at once
- 🔍 **Safe mode** — run `/upkeep:check` to preview every available update before committing to changes
- 📊 **Structured reports** — Markdown tables with version diffs so you see exactly what changed
- 🛡️ **Fault tolerant** — a single component failure never blocks the rest of your updates
- 🧯 **Safe by default** — Python/conda environments and macOS updates are reported, never applied; git MCP checkouts with local changes are skipped
- 🪶 **Lightweight** — SKILL.md instructions plus two small read-only bash helpers (needs `jq`; `gh` optional)

---

## Quick Start

**1. Install the plugin**

```
/plugin install upkeep --marketplace allenhuang0/claude-upkeep
```

**2. Reload plugins**

```
/reload-plugins
```

Then run `/upkeep:check` to preview, or `/upkeep` to update everything.

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
| Claude Code CLI | `claude --version` vs `npm view` | `claude update` |
| Plugin marketplaces | `git fetch` + commit count | `claude plugin marketplace update` |
| Claude Code plugins | `installed_plugins.json` | `claude plugin update` |
| Agent skills (`npx skills`) | lock-file hash vs GitHub tree SHA | `npx skills update -g` |
| npm global packages | `npm outdated -g` | `npm install -g <pkg>@latest` |
| Homebrew formulae + casks | `brew outdated --json=v2` | `brew upgrade` |
| MCP servers via `npx` | npx cache version vs `npm view` | clear stale npx cache |
| MCP servers from git checkouts | `git fetch` + log compare | `git pull --ff-only` + rebuild |
| uv tools | `uv tool list --outdated` | `uv tool upgrade` |
| Rust / Bun toolchains | `rustup check`, `bun --version` | `rustup update`, `bun upgrade` |
| Python / conda environments | `pip list --outdated` per env | report only |
| macOS | `softwareupdate -l` | report only |

MCP servers are read from `~/.claude.json` (user and project scope).

-----------|-----------|---------------|
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

npm globals are installed as `<pkg>@latest`, so major versions are included. Run `/upkeep:check` first to review what would change before applying updates.

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
