# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repo holds a collection of Claude Code plugins, skills, and slash commands for interacting with macOS (system apps, settings, files, automation).

## Status

The repository is new and has no code, build tooling, or tests yet. Update this file once the first plugin lands: add the real layout, any build/lint/test commands, and the conventions that emerge.

## Layout: plugin marketplace

The repo is a Claude Code plugin marketplace:

- `.claude-plugin/marketplace.json` at the repo root lists every plugin (name, `source` path, description). Add an entry here whenever a plugin is added, renamed, or removed; a plugin missing from it can't be installed from the marketplace.
- Each plugin lives in its own directory under `plugins/<plugin-name>/`, with `.claude-plugin/plugin.json` and any of:
  - `skills/<skill-name>/SKILL.md` — model-invoked skills (frontmatter `name` + `description`; the description drives when the skill triggers)
  - `commands/<name>.md` — user-invoked slash commands
  - `agents/<name>.md` — subagents
  - `hooks/hooks.json` — hooks
  - `.mcp.json` — bundled MCP servers
- Reference files inside a plugin with `${CLAUDE_PLUGIN_ROOT}` rather than absolute paths.

## Versioning

Don't bump plugin versions by hand. Two workflows handle it:

1. `version-bump-advisor` (a gh-aw agentic workflow; edit `version-bump-advisor.md`, then run `gh aw compile` to regenerate the `.lock.yml`) comments on each PR touching `plugins/**` with a recommended major/minor/patch bump per plugin. The comment ends with a fenced ` ```version-bump ` block of `<plugin>: <level>` lines — that block is a contract, not decoration.
2. `bump-plugin-versions` runs on push to `main`. `.github/scripts/advisor-bump-levels.sh` finds the PRs merged in the push and reads the newest `version-bump` block posted by `github-actions[bot]` on each; `.github/scripts/bump-plugin-versions.sh` applies those levels (patch for any changed plugin without a recommendation, e.g. direct pushes) and pushes a `[skip ci]` commit back to `main`. It then runs `.github/scripts/tag-plugin-versions.sh`, which creates and pushes an annotated `<plugin-name>-v<version>` tag (name from `plugin.json`) for every plugin whose current version isn't tagged yet, so hand-edited versions and new plugins get tagged too.

A plugin whose `version` line was edited in the push (including a newly added plugin) is left as-is, which is how to override the advisor. Pull after merging, since CI adds a commit on top.

## Testing locally

Load a plugin into a session without installing it:

```bash
claude --plugin-dir ./plugins/<plugin-name>
```

To test the marketplace itself, add this repo from inside Claude Code with `/plugin marketplace add <path-to-repo>`, then `/plugin install <plugin-name>@<marketplace-name>`.

## macOS notes

- macOS automation (AppleScript/JXA via `osascript`, `shortcuts`, `defaults`, etc.) often triggers TCC privacy prompts (Automation, Accessibility, Full Disk Access). Skills should explain the needed permission when a command fails for that reason rather than retrying.
