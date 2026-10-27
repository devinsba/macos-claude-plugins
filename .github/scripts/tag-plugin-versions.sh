#!/usr/bin/env bash
# Create an annotated "<plugin-name>-v<version>" tag at HEAD for every plugin
# whose current version has no tag yet. This covers CI bumps, hand-edited
# versions, and new plugins alike. Prints each tag it creates; pushing is
# left to the caller. Needs existing tags fetched locally.
#
# Usage: tag-plugin-versions.sh
set -euo pipefail

for manifest in plugins/*/.claude-plugin/plugin.json; do
  [[ -f "$manifest" ]] || continue
  name=$(jq -r '.name // empty' "$manifest")
  version=$(jq -r '.version // empty' "$manifest")
  if [[ -z "$name" || -z "$version" ]]; then
    echo "::warning file=$manifest::skipping: missing name or version" >&2
    continue
  fi

  tag="$name-v$version"
  git rev-parse -q --verify "refs/tags/$tag" >/dev/null && continue

  git tag -a "$tag" -m "$name $version"
  echo "$tag"
done
