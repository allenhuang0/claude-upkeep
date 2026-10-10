# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-10-09

### Added
- Agent skills installed with `npx skills`: read-only check against GitHub, update via `npx skills update`
- uv tools, Rust (`rustup`) and Bun toolchains
- Python / conda environments and macOS updates, reported but never applied
- Plugin marketplaces are refreshed before plugins update
- MCP servers launched through `npx` (stale npx cache detection)

### Changed
- MCP servers are read from `~/.claude.json` (user and project scope) instead of the nonexistent `~/.claude/mcp.json`
- Git-based MCP servers with local changes are skipped; others pull fast-forward only and rebuild (`uv sync`, `npm install` + build, or `pip install -r`)
- npm globals install `@latest`, so major versions are included
- Claude Code CLI updates through `claude update`
- Reports list only components that are not up to date, with per-type counts
- `/upkeep` reuses the scan steps of `/upkeep:check` instead of duplicating them

## [1.0.0] - 2026-03-31

### Added
- `/upkeep` skill — auto-update all Claude Code ecosystem components
- `/upkeep:check` skill — check for updates without making changes
- Covers: plugins, npm globals, Homebrew, git MCP servers, pip MCP servers, CLI
- Structured Markdown report with update summary
- Zero dependencies — pure SKILL.md implementation
