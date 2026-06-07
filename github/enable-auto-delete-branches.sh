#!/usr/bin/env zsh

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: $0 [--repo <name> ...]"
  echo ""
  echo "Enables auto-delete of head branches after merge."
  echo "Targets specified repos, or all repos in your account if none are given."
  echo ""
  echo "Arguments:"
  echo "  --repo <name>  Repository name (can be specified multiple times)"
  echo ""
  echo "Examples:"
  echo "  $0"
  echo "  $0 --repo dotfiles"
  echo "  $0 --repo dotfiles --repo scripts"
  exit 0
fi

REPOS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --repo requires a value" >&2
        exit 1
      fi
      REPOS+=("$2")
      shift 2
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

OWNER=$(gh api user --jq '.login')

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "Fetching repos for: $OWNER"
  REPOS=("${(@f)$(gh repo list "$OWNER" --limit 1000 --json name --jq '.[].name')}")
fi

for REPO in "${REPOS[@]}"; do
  gh api \
    --method PATCH \
    "repos/$OWNER/$REPO" \
    -f delete_branch_on_merge=true \
    --silent

  echo "  [$REPO] auto-delete head branches enabled"
done

echo "Done."
