#!/usr/bin/env bash
# Print "<plugin> <major|minor|patch>" for each plugin the version-bump-advisor
# recommended on the PRs merged in BASE..HEAD. Reads the advisor's latest
# comment on each PR and its ```version-bump block. When several PRs name the
# same plugin, the highest bump wins.
#
# Usage: advisor-bump-levels.sh <base-commit>
# Needs GH_TOKEN and GITHUB_REPOSITORY.
set -euo pipefail

base="${1:-}"
if [[ -z "$base" || "$base" =~ ^0+$ ]] || ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
  range=HEAD
else
  range="$base..HEAD"
fi

prs=$(
  for sha in $(git rev-list "$range"); do
    gh api "repos/$GITHUB_REPOSITORY/commits/$sha/pulls" \
      --jq '.[] | select(.merged_at != null) | .number'
  done | sort -un
)

for pr in $prs; do
  # Only trust comments posted by the workflow's bot, newest last.
  gh api --paginate "repos/$GITHUB_REPOSITORY/issues/$pr/comments" \
    --jq '.[] | select(.user.login == "github-actions[bot]") | select(.body | contains("```version-bump")) | .body' \
    | awk '
        /^```version-bump[[:space:]]*$/ { n++; inblock = 1; next }
        inblock && /^```/              { inblock = 0; next }
        inblock                        { lines[n] = lines[n] $0 "\n" }
        END                            { printf "%s", lines[n] }
      '
done | awk -F: '
  {
    plugin = $1; level = $2
    gsub(/[[:space:]]/, "", plugin); gsub(/[[:space:]]/, "", level)
    rank = (level == "major") ? 3 : (level == "minor") ? 2 : (level == "patch") ? 1 : 0
    if (plugin == "" || rank == 0) next
    if (rank > best[plugin]) { best[plugin] = rank; name[plugin] = level }
  }
  END { for (p in best) print p, name[p] }
' | sort
