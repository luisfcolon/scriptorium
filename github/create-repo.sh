#!/usr/bin/env zsh

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: $0 <repo-name> [--private|--public] [--code-owner]"
  echo ""
  echo "Creates a GitHub repo with:"
  echo "  - main as the default branch"
  echo "  - branch protection (1 required reviewer, dismiss stale reviews)"
  echo ""
  echo "Arguments:"
  echo "  repo-name      Name of the repository to create"
  echo "  --public       Make the repo public (default)"
  echo "  --private      Make the repo private"
  echo "  --code-owner   Create a .github/CODEOWNERS file with you as the owner"
  echo ""
  echo "Examples:"
  echo "  $0 my-repo"
  echo "  $0 my-repo --private"
  echo "  $0 my-repo --private --code-owner"
  exit 0
fi

REPO_NAME=${1:?Usage: $0 <repo-name> [--private|--public] [--code-owner]}
VISIBILITY="--public"
CODE_OWNER=false

for arg in "${@:2}"; do
  case "$arg" in
    --private) VISIBILITY="--private" ;;
    --public)  VISIBILITY="--public" ;;
    --code-owner) CODE_OWNER=true ;;
  esac
done

OWNER=$(gh api user --jq '.login')

echo "Creating GitHub repository: $REPO_NAME"

# Create repo with main as the default branch
gh repo create "$OWNER/$REPO_NAME" \
  "$VISIBILITY" \
  --add-readme

echo "[$REPO_NAME] created"

# Apply branch protection to main
gh api \
  --method PUT \
  "repos/$OWNER/$REPO_NAME/branches/main/protection" \
  --input - <<'EOF'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF

echo "[$REPO_NAME] main set as default with branch protection applied"

if [[ "$CODE_OWNER" == true ]]; then
  gh api \
    --method PUT \
    "repos/$OWNER/$REPO_NAME/contents/.github/CODEOWNERS" \
    -f message="Add CODEOWNERS" \
    -f content="$(printf '* @%s' "$OWNER" | base64)"

  echo "[$REPO_NAME] .github/CODEOWNERS created with @$OWNER as owner"
fi
