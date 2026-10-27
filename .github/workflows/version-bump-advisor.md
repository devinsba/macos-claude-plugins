---
name: Version Bump Advisor
description: Recommends a semver bump (major/minor/patch) for each plugin touched by a pull request
on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - "plugins/**"
permissions:
  contents: read
  pull-requests: read
  copilot-requests: write
engine: copilot
tools:
  bash:
    - "git:*"
    - safeoutputs
safe-outputs:
  add-comment:
    max: 1
    replace-older-comments: true
timeout-minutes: 10
---

# Version Bump Advisor

This repo is a Claude Code plugin marketplace. Each plugin lives under
`plugins/<plugin-name>/` and has its own semantic version in
`plugins/<plugin-name>/.claude-plugin/plugin.json`.

**Repository**: ${{ github.repository }}
**Base SHA**: ${{ github.event.pull_request.base.sha }}
**Head SHA**: ${{ github.event.pull_request.head.sha }}

## Steps

1. Find every plugin touched by this PR:
   `git diff --name-only <base-sha> <head-sha> -- plugins/`
   using the real SHAs above, then take the unique `plugins/<name>` segment
   of each path.
2. For each touched plugin:
   - Read its current `version` from
     `plugins/<plugin-name>/.claude-plugin/plugin.json`.
   - Review the full diff of that plugin's files in this PR:
     `git diff <base-sha> <head-sha> -- plugins/<plugin-name>`
3. Classify the change using semver:
   - **major** — a breaking change (removed/renamed a command, skill, or
     tool; changed required inputs/outputs; anything that would break an
     existing user of the plugin)
   - **minor** — a backward-compatible addition (new skill, command, agent,
     hook, or capability)
   - **patch** — a backward-compatible fix or tweak (bug fix, wording,
     docs, minor behavior correction, refactor with no behavior change)

   If a plugin's changes mix categories, pick the highest
   (major > minor > patch).
4. Check whether the PR already hand-edited that plugin's `version` field:
   `git diff <base-sha> <head-sha> -- plugins/<plugin-name>/.claude-plugin/plugin.json`
   If it did, just confirm whether the new version matches your
   recommended bump instead of recommending one from scratch, and say so.
5. Post one PR comment with a markdown table: `Plugin | Current version |
   Recommended bump | Why`. Keep "Why" to one short sentence per plugin.

   After the table, add a fenced code block whose info string is exactly
   `version-bump`, with one line per touched plugin in the form
   `<plugin-name>: <major|minor|patch>` and nothing else. The
   `bump-plugin-versions` workflow parses this block on merge to decide
   each plugin's bump, so keep it exact. For example:

   ````
   ```version-bump
   apple-reminders: minor
   ```
   ````

   End with one line: "These bumps are applied automatically on merge. To
   override one, edit the version in plugin.json by hand in this PR."

   Post it with the `safeoutputs` CLI from bash, piping JSON on stdin, for
   example:

   ```bash
   printf '%s' '{"body":"COMMENT_BODY"}' | safeoutputs add_comment .
   ```

   JSON-escape the body (encode apostrophes as `'`, newlines as `\n`)
   and do not use shell double quotes around it. If the PR touches no
   plugins (for example, only `marketplace.json` changed), skip posting a
   comment entirely.
