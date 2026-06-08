# GitHub Scripts

Scripts for managing GitHub repositories via the `gh` CLI.

You must be authenticated with the GitHub CLI before running any of these scripts.

```bash
gh auth login
```

## Scripts

- [add-codeowners.sh](#add-codeownerssh)
- [create-repo.sh](create-repo/README.md)
- [enable-auto-delete-branches.sh](#enable-auto-delete-branchessh)
- [migrate-master-to-main.sh](#migrate-master-to-mainsh)
- [update-repo.sh](update-repo/README.md)

## add-codeowners.sh

Creates a `.github/CODEOWNERS` file in one or more repositories with you as the default owner.

**What it does:**

- Creates a `chore/add-codeowners` branch off the default branch
- Adds `* @<you>` to `.github/CODEOWNERS`
- Creates one or more PRs and prints all of their URLs together at the end
- If a CODEOWNERS file already exists, it will prompts to override or ignore

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

See [create-repo/README.md](create-repo/README.md).

## enable-auto-delete-branches.sh

Enables the "Automatically delete head branches" setting on one or more repositories, or all of them if none are specified.

**What it does:**

- Targets specified repos, or all repos in your account (up to 1000) if no `--repo` flags are given
- Sets `delete_branch_on_merge` to `true` on each repo

**Usage:**

```bash
./enable-auto-delete-branches.sh [--repo <name> ...]
```

**Arguments:**

- `--repo <name>` — repository name, can be specified multiple times

**Examples:**

```bash
./enable-auto-delete-branches.sh
./enable-auto-delete-branches.sh --repo dotfiles
./enable-auto-delete-branches.sh --repo dotfiles --repo scripts
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

## update-repo.sh

See [update-repo/README.md](update-repo/README.md).
