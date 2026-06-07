# GitHub Scripts

Scripts for managing GitHub repositories via the `gh` CLI.

You must be authenticated with the GitHub CLI before running any of these scripts.

```bash
gh auth login
```

## Scripts

- [add-codeowners.sh](#add-codeownerssh)
- [create-repo.sh](#create-reposh)
- [enable-auto-delete-branches.sh](#enable-auto-delete-branchessh)
- [migrate-master-to-main.sh](#migrate-master-to-mainsh)

## add-codeowners.sh

Creates a `.github/CODEOWNERS` file in one or more repositories with you as the default owner. Opens a PR against the default branch rather than committing directly.

**What it does:**

- Creates a `chore/add-codeowners` branch off the default branch
- Adds `* @<you>` to `.github/CODEOWNERS`
- Opens a PR and prints all PR URLs together at the end
- If a CODEOWNERS file already exists, prompts before overriding
- `--repo` takes priority if both flags are provided

**Usage:**

```bash
./add-codeowners.sh --repo <name> [--repo <name> ...] | --all-repos [--auto-merge]
```

**Arguments:**

- `--repo <name>` — repository name, can be specified multiple times
- `--all-repos` — target all repos in your account
- `--auto-merge` — merge the PR immediately after creating it

**Examples:**

```bash
./add-codeowners.sh --repo dotfiles
./add-codeowners.sh --repo dotfiles --repo scripts
./add-codeowners.sh --all-repos
./add-codeowners.sh --all-repos --auto-merge
```

## create-repo.sh

Creates a new GitHub repository with `main` as the default branch and branch protection enabled.

**What it does:**

- Creates a public or private repo under your GitHub account
- Adds a default README
- Sets `main` as the default branch
- Applies branch protection: 1 required reviewer, stale review dismissal
- Optionally creates a `.github/CODEOWNERS` file with you as the owner

**Usage:**

```bash
./create-repo.sh <repo-name> [--private|--public] [--code-owner]
```

**Arguments:**

- `repo-name` — name of the repository to create
- `--public` — make the repo public (default)
- `--private` — make the repo private
- `--code-owner` — create a `.github/CODEOWNERS` file with you as the owner

**Examples:**

```bash
./create-repo.sh my-repo
./create-repo.sh my-repo --private
./create-repo.sh my-repo --private --code-owner
```

## enable-auto-delete-branches.sh

Enables the "Automatically delete head branches" setting across all repositories in your GitHub account.

**What it does:**

- Iterates over all repos (up to 1000) in your account
- Sets `delete_branch_on_merge` to `true` on each repo

**Usage:**

```bash
./enable-auto-delete-branches.sh
```

## migrate-master-to-main.sh

Renames the `master` branch to `main` across all repositories in your GitHub account.

**What it does:**

- Iterates over all repos (up to 1000) in your account
- Skips repos that have no `master` branch or already have a `main` branch
- Renames `master` → `main` (open PRs are retargeted automatically)
- Sets `main` as the default branch

**Usage:**

```bash
./migrate-master-to-main.sh
```
