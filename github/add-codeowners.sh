#!/usr/bin/env zsh

set -euo pipefail

usage() {
  echo "Usage: $0 --repo <name> [--repo <name> ...] [--auto-merge]"
  echo ""
  echo "Creates a .github/CODEOWNERS file in the specified repos with you as the owner."
  echo "Opens a PR against the default branch."
  echo ""
  echo "Arguments:"
  echo "  --repo <name>   Repository name (can be specified multiple times)"
  echo "  --auto-merge    Merge the PR immediately after creating it"
  echo ""
  echo "Examples:"
  echo "  $0 --repo dotfiles"
  echo "  $0 --repo dotfiles --repo scripts"
  echo "  $0 --repo dotfiles --auto-merge"
  echo ""
  exit 1
}

REPOS=()
AUTO_MERGE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ -z "${2:-}" ]] && { echo "Error: --repo requires a value"; usage; }
      REPOS+=("$2")
      shift 2
      ;;
    --auto-merge)
      AUTO_MERGE=true
      shift
      ;;
    --help|-h) usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "Error: must provide at least one --repo"
  echo ""
  usage
fi

OWNER=$(gh api user --jq '.login')

CONTENT=$(printf '* @%s\n' "$OWNER" | base64)
BRANCH="chore/add-codeowners"
PR_URLS=()

add_codeowners() {
  local REPO="$1"
  local EXISTING_SHA=""

  if gh api "repos/$OWNER/$REPO/contents/.github/CODEOWNERS" --silent 2>/dev/null; then
    EXISTING_SHA=$(gh api "repos/$OWNER/$REPO/contents/.github/CODEOWNERS" --jq '.sha')
  fi

  if [[ -n "$EXISTING_SHA" ]]; then
    read -r "answer?  [$REPO] CODEOWNERS already exists. Override? [y/N] "
    if [[ "${answer:l}" != "y" ]]; then
      echo "  [$REPO] skipped"
      return
    fi
  fi

  local DEFAULT_BRANCH
  DEFAULT_BRANCH=$(gh api "repos/$OWNER/$REPO" --jq '.default_branch')

  local BASE_SHA
  BASE_SHA=$(gh api "repos/$OWNER/$REPO/git/ref/heads/$DEFAULT_BRANCH" --jq '.object.sha')

  if gh api "repos/$OWNER/$REPO/git/ref/heads/$BRANCH" --silent 2>/dev/null; then
    gh api --method DELETE "repos/$OWNER/$REPO/git/refs/heads/$BRANCH" --silent
  fi

  gh api \
    --method POST \
    "repos/$OWNER/$REPO/git/refs" \
    -f ref="refs/heads/$BRANCH" \
    -f sha="$BASE_SHA" \
    --silent

  local -a put_args=(-f message="Add CODEOWNERS" -f content="$CONTENT" -f branch="$BRANCH")
  [[ -n "$EXISTING_SHA" ]] && put_args+=(-f sha="$EXISTING_SHA")

  gh api \
    --method PUT \
    "repos/$OWNER/$REPO/contents/.github/CODEOWNERS" \
    "${put_args[@]}" \
    --silent

  local PR_NUMBER PR_URL
  read -r PR_NUMBER PR_URL < <(gh api \
    --method POST \
    "repos/$OWNER/$REPO/pulls" \
    -f title="chore: Add CODEOWNERS" \
    -f body="Adds \`.github/CODEOWNERS\` with \`@$OWNER\` as the default owner for all files." \
    -f head="$BRANCH" \
    -f base="$DEFAULT_BRANCH" \
    --jq '[.number, .html_url] | @tsv')

  if [[ "$AUTO_MERGE" == true ]]; then
    gh api \
      --method PUT \
      "repos/$OWNER/$REPO/pulls/$PR_NUMBER/merge" \
      -f merge_method="squash" \
      --silent

    echo "  [$REPO] CODEOWNERS added and PR merged"
  else
    PR_URLS+=("$PR_URL")
    echo "  [$REPO] PR created"
  fi
}

for REPO in "${REPOS[@]}"; do
  add_codeowners "$REPO"
done

if [[ ${#PR_URLS[@]} -gt 0 ]]; then
  echo ""
  echo "Open PRs:"
  for URL in "${PR_URLS[@]}"; do
    echo "  $URL"
  done
fi

echo ""
