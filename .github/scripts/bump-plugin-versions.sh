#!/usr/bin/env bash
# Bump the version of every plugin changed since BASE.
# LEVELS is an optional file of "<plugin> <major|minor|patch>" lines (from
# advisor-bump-levels.sh); plugins not listed get a patch bump. Plugins whose
# version was edited by hand in that range (including new plugins) are left
# alone. Prints the bumped plugins as "name old -> new (level)".
#
# Usage: bump-plugin-versions.sh <base-commit> [levels-file]
set -euo pipefail

base="${1:-}"
# A new branch (all-zero SHA) or an unknown commit: compare against the empty tree.
if [[ -z "$base" || "$base" =~ ^0+$ ]] || ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
  base=$(git hash-object -t tree /dev/null)
fi
levels="${2:-/dev/null}"

plugins=$(git diff --name-only "$base" HEAD -- plugins/ | cut -d/ -f2 | sort -u)

for plugin in $plugins; do
  manifest="plugins/$plugin/.claude-plugin/plugin.json"
  [[ -f "$manifest" ]] || continue

  if git diff "$base" HEAD -- "$manifest" | grep -qE '^[+-][[:space:]]*"version"'; then
    continue
  fi

  old=$(jq -r '.version // empty' "$manifest")
  if [[ ! "$old" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "::warning file=$manifest::skipping $plugin: version '$old' is not MAJOR.MINOR.PATCH" >&2
    continue
  fi
  major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} patch=${BASH_REMATCH[3]}

  level=$(awk -v p="$plugin" '$1 == p { print $2 }' "$levels" | tail -n1)
  case "${level:-patch}" in
    major) new="$((major + 1)).0.0"; level=major ;;
    minor) new="$major.$((minor + 1)).0"; level=minor ;;
    *)     new="$major.$minor.$((patch + 1))"; level=patch ;;
  esac

  # Edit the line in place so the file's formatting is kept.
  sed -i.bak -E "s/(\"version\"[[:space:]]*:[[:space:]]*\")${old//./\\.}\"/\1${new}\"/" "$manifest"
  rm -f "$manifest.bak"

  echo "$plugin $old -> $new ($level)"
done
