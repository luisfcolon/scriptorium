# create-repo.sh

Creates a new GitHub repository with branch protection enabled.

**What it does:**

- Creates a public or private repo under your GitHub account
- Adds a default README and a boilerplate `.gitignore`
- Applies repo settings from a JSON config file, or a built-in default (`delete_branch_on_merge: true`)
- Sets `main` as the default and protected branch (unless `--protect` is used)
- When `--protect` is used, prompts you to choose the default branch from all protected branches
- Applies the same branch protection rules to every protected branch: 1 required reviewer, stale review dismissal
- Optionally creates a `.github/CODEOWNERS` file with you as the owner and enables required code owner reviews on all protected branches

**Usage:**

```bash
./create-repo.sh <repo-name> [--private|--public] [--codeowner] [--protect <branch>...] [--no-main] [--config <file>]
```

**Arguments:**

- `repo-name` — name of the repository to create
- `--public` — make the repo public (default)
- `--private` — make the repo private
- `--codeowner` — create a `.github/CODEOWNERS` file with you as the owner and require code owner reviews on all protected branches
- `--protect <name>` — protect an additional branch; repeatable
- `--no-main` — exclude `main` from protected branches and delete it after creation (requires at least one `--protect`)
- `--config <file>` — JSON file of repo settings to apply; replaces the default config
- `--print-default-config` — print the default repo config and exit

See [`example-config.json`](example-config.json) for available settings.

**Examples:**

```bash
./create-repo.sh my-repo
./create-repo.sh my-repo --private
./create-repo.sh my-repo --private --codeowner
./create-repo.sh my-repo --protect develop --protect staging
./create-repo.sh my-repo --protect edge --protect staging --protect prod --no-main
./create-repo.sh my-repo --config ./example-config.json
```
