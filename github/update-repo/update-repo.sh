#!/usr/bin/env zsh

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: $0 <repo-name> --config <file>"
  echo ""
  echo "Applies repo settings from a JSON config file to an existing GitHub repository."
  echo ""
  echo "Arguments:"
  echo "  repo-name       Name of the repository to update"
  echo "  --config <file> JSON file of repo settings to apply (required)"
  echo ""
  echo "Examples:"
  echo "  $0 my-repo --config ./example-config.json"
  exit 0
fi

REPO_NAME=${1:?Usage: $0 <repo-name> --config <file>}
shift

CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      if [[ $# -lt 2 || "${2:-}" == --* ]]; then
        echo "Error: --config requires a file path" >&2
        exit 1
      fi
      if [[ ! -f "$2" ]]; then
        echo "Error: config file not found: $2" >&2
        exit 1
      fi
      CONFIG_FILE="$2"
      shift
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$CONFIG_FILE" ]]; then
  echo "Error: --config is required" >&2
  exit 1
fi

OWNER=$(gh api user --jq '.login')

gh api \
  --method PATCH \
  "repos/$OWNER/$REPO_NAME" \
  --input - < "$CONFIG_FILE" \
  --silent

echo "[$REPO_NAME] repo settings applied from $(basename "$CONFIG_FILE")"
