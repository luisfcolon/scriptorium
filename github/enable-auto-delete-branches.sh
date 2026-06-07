#!/usr/bin/env zsh

set -euo pipefail

OWNER=$(gh api user --jq '.login')
echo "Fetching repos for: $OWNER"

REPOS=("${(@f)$(gh repo list "$OWNER" --limit 1000 --json name --jq '.[].name')}")

for REPO in "${REPOS[@]}"; do
  gh api \
    --method PATCH \
    "repos/$OWNER/$REPO" \
    -f delete_branch_on_merge=true \
    --silent

  echo "  [$REPO] auto-delete head branches enabled"
done

echo "Done."
