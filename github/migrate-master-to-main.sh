#!/usr/bin/env zsh

set -euo pipefail

OWNER=$(gh api user --jq '.login')
echo "Fetching repos for: $OWNER"

REPOS=$(gh repo list "$OWNER" --limit 1000 --json name --jq '.[].name')

for REPO in $REPOS; do
  # Skip if no master branch
  if ! gh api "repos/$OWNER/$REPO/branches/master" --silent 2>/dev/null; then
    echo "  [$REPO] no master branch, skipping"
    continue
  fi

  # Skip if main already exists
  if gh api "repos/$OWNER/$REPO/branches/main" --silent 2>/dev/null; then
    echo "  [$REPO] main already exists, skipping"
    continue
  fi

  # Rename master to main (retargets open PRs automatically)
  gh api \
    --method POST \
    "repos/$OWNER/$REPO/branches/master/rename" \
    -f new_name="main"

  echo "  [$REPO] renamed master to main"

  # Set main as the default branch
  gh api \
    --method PATCH \
    "repos/$OWNER/$REPO" \
    -f default_branch="main"

  echo "  [$REPO] set main as default branch"

done

echo "Done."
