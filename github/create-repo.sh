#!/usr/bin/env zsh

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: $0 <repo-name> [--private|--public] [--codeowner] [--protect <branch>...]"
  echo ""
  echo "Creates a GitHub repo with:"
  echo "  - main as the default branch (or chosen when --protect is used)"
  echo "  - auto-delete of head branches after merge"
  echo "  - branch protection (1 required reviewer, dismiss stale reviews)"
  echo ""
  echo "Arguments:"
  echo "  repo-name         Name of the repository to create"
  echo "  --public          Make the repo public (default)"
  echo "  --private         Make the repo private"
  echo "  --codeowner       Create a .github/CODEOWNERS file and require code owner reviews"
  echo "  --protect <name>  Protect an additional branch (repeatable)"
  echo "  --no-main         Exclude main from protected branches (requires --protect)"
  echo ""
  echo "Examples:"
  echo "  $0 my-repo"
  echo "  $0 my-repo --private"
  echo "  $0 my-repo --private --codeowner"
  echo "  $0 my-repo --protect develop --protect staging"
  echo "  $0 my-repo --protect develop --protect staging --protect prod --no-main"
  exit 0
fi

REPO_NAME=${1:?Usage: $0 <repo-name> [--private|--public] [--codeowner] [--protect <branch>...]}
shift

VISIBILITY="--public"
CODE_OWNER=false
NO_MAIN=false
EXTRA_BRANCHES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --private)    VISIBILITY="--private" ;;
    --public)     VISIBILITY="--public" ;;
    --codeowner) CODE_OWNER=true ;;
    --no-main)    NO_MAIN=true ;;
    --protect)
      if [[ $# -lt 2 || "${2:-}" == --* ]]; then
        echo "Error: --protect requires a branch name argument" >&2
        exit 1
      fi
      shift
      [[ "$1" != "main" ]] && EXTRA_BRANCHES+=("$1")
      ;;
  esac
  shift
done

if [[ "$NO_MAIN" == true && ${#EXTRA_BRANCHES[@]} -eq 0 ]]; then
  echo "Error: --no-main requires at least one --protect branch" >&2
  exit 1
fi

if [[ "$NO_MAIN" == true ]]; then
  PROTECTED_BRANCHES=("${EXTRA_BRANCHES[@]}")
else
  PROTECTED_BRANCHES=("main" "${EXTRA_BRANCHES[@]}")
fi

if [[ ${#EXTRA_BRANCHES[@]} -gt 0 ]]; then
  echo "Select the default branch:"
  COLUMNS=1
  PS3="Enter number: "
  select DEFAULT_BRANCH in "${PROTECTED_BRANCHES[@]}"; do
    [[ -n "$DEFAULT_BRANCH" ]] && break
    echo "Invalid selection, try again"
  done
else
  DEFAULT_BRANCH="main"
fi

OWNER=$(gh api user --jq '.login')

echo "Creating GitHub repository: $REPO_NAME"

gh repo create "$OWNER/$REPO_NAME" \
  "$VISIBILITY" \
  --add-readme

echo "[$REPO_NAME] created"

gh api \
  --method PUT \
  "repos/$OWNER/$REPO_NAME/contents/.gitignore" \
  -f message="Add .gitignore" \
  -f content="$(printf '# OS\n.DS_Store\nThumbs.db\n._*\n\n# Editor\n.vscode/\n.idea/\n*.swp\n*.swo\n\n# Environment\n.env\n\n# Credentials\n*.pem\n*.cert\n*.key\n\n# Logs\n*.log\ncrash.log\n\n# Runtime\n*.rdb\n\n# Worktrees\n.worktrees\n*-worktree\n' | base64)" \
  --silent

echo "[$REPO_NAME] .gitignore created"

# Enable auto-delete of head branches after merge
gh api \
  --method PATCH \
  "repos/$OWNER/$REPO_NAME" \
  -f delete_branch_on_merge=true \
  --silent

echo "[$REPO_NAME] auto-delete head branches enabled"

# Create extra branches and set the default if needed
if [[ ${#EXTRA_BRANCHES[@]} -gt 0 ]]; then
  MAIN_SHA=$(gh api "repos/$OWNER/$REPO_NAME/git/ref/heads/main" --jq '.object.sha')

  for branch in "${EXTRA_BRANCHES[@]}"; do
    gh api \
      --method POST \
      "repos/$OWNER/$REPO_NAME/git/refs" \
      -f ref="refs/heads/$branch" \
      -f sha="$MAIN_SHA" \
      --silent
    echo "[$REPO_NAME] branch '$branch' created"
  done

  if [[ "$DEFAULT_BRANCH" != "main" ]]; then
    gh api \
      --method PATCH \
      "repos/$OWNER/$REPO_NAME" \
      -f default_branch="$DEFAULT_BRANCH" \
      --silent
    echo "[$REPO_NAME] default branch set to '$DEFAULT_BRANCH'"
  fi

  if [[ "$NO_MAIN" == true ]]; then
    gh api \
      --method DELETE \
      "repos/$OWNER/$REPO_NAME/git/refs/heads/main" \
      --silent
    echo "[$REPO_NAME] branch 'main' deleted"
  fi
fi

# Apply branch protection to all protected branches
apply_protection() {
  local branch="$1"
  local codeowner_reviews="false"
  [[ "$CODE_OWNER" == true ]] && codeowner_reviews="true"

  gh api \
    --method PUT \
    "repos/$OWNER/$REPO_NAME/branches/$branch/protection" \
    --input - <<EOF
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "required_approving_review_count": 1,
    "require_code_owner_reviews": $codeowner_reviews
  },
  "restrictions": null
}
EOF
  echo "[$REPO_NAME] branch protection applied to '$branch'"
}

for branch in "${PROTECTED_BRANCHES[@]}"; do
  apply_protection "$branch"
done

if [[ "$CODE_OWNER" == true ]]; then
  gh api \
    --method PUT \
    "repos/$OWNER/$REPO_NAME/contents/.github/CODEOWNERS" \
    -f message="Add CODEOWNERS" \
    -f content="$(printf '* @%s' "$OWNER" | base64)"

  echo "[$REPO_NAME] .github/CODEOWNERS created with @$OWNER as owner"
fi
