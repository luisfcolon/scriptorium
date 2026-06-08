# update-repo.sh

Applies repo settings from a JSON config file to an existing GitHub repository.

**What it does:**

- Sends a `PATCH /repos/{owner}/{repo}` request with the contents of the config file
- Only the fields present in the config are updated — omitted fields are left as-is

**Usage:**

```bash
./update-repo.sh <repo-name> --config <file>
```

**Arguments:**

- `repo-name` — name of the repository to update
- `--config <file>` — JSON file of repo settings to apply (required)

See [`example-config.json`](example-config.json) for available settings.

**Examples:**

```bash
./update-repo.sh my-repo --config ./example-config.json
```
