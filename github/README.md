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

**Usage:**

```bash
./add-codeowners.sh --repo <name> [--repo <name> ...] [--auto-merge]
```

**Arguments:**

- `--repo <name>` — repository name, can be specified multiple times
- `--auto-merge` — merge the PR immediately after creating it

**Examples:**

```bash
./add-codeowners.sh --repo dotfiles
./add-codeowners.sh --repo dotfiles --repo scripts
./add-codeowners.sh --repo dotfiles --auto-merge
```

## create-repo.sh

Creates a new GitHub repository with branch protection enabled.

**What it does:**

- Creates a public or private repo under your GitHub account
- Adds a default README and a boilerplate `.gitignore`
- Enables auto-delete of head branches after merge
- Sets `main` as the default and protected branch (unless `--protect` is used)
- When `--protect` is used, prompts you to choose the default branch from all protected branches
- Applies the same branch protection rules to every protected branch: 1 required reviewer, stale review dismissal
- Optionally creates a `.github/CODEOWNERS` file with you as the owner and enables required code owner reviews on all protected branches

**Usage:**

```bash
./create-repo.sh <repo-name> [--private|--public] [--codeowner] [--protect <branch>...] [--no-main]
```

**Arguments:**

- `repo-name` — name of the repository to create
- `--public` — make the repo public (default)
- `--private` — make the repo private
- `--codeowner` — create a `.github/CODEOWNERS` file with you as the owner and require code owner reviews on all protected branches
- `--protect <name>` — protect an additional branch; repeatable
- `--no-main` — exclude `main` from protected branches and delete it after creation (requires at least one `--protect`)

**Examples:**

```bash
./create-repo.sh my-repo
./create-repo.sh my-repo --private
./create-repo.sh my-repo --private --codeowner
./create-repo.sh my-repo --protect develop --protect staging
./create-repo.sh my-repo --protect edge --protect staging --protect prod --no-main
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
