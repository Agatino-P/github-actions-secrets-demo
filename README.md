# GitHub Actions Secrets — Practice Repo

A minimal repo for practicing GitHub Actions **Secrets** and **Variables**.
A shell script reads one secret and one variable, confirms the secret arrived
(without printing it), and prints the variable plainly.

## Files

- `check_secrets.sh` — the script that reads `MY_SECRET` and `MY_GREETING`.
- `.github/workflows/secrets-demo.yml` — the workflow that runs the script.

## Setup

1. **Add a repository Secret** (sensitive):
   - Repo **Settings** → **Secrets and variables** → **Actions** → **Secrets** tab → **New repository secret**
   - Name: `MY_SECRET`
   - Value: anything you like (e.g. `super-secret-123`)

2. **Add a repository Variable** (non-sensitive):
   - Same page → **Variables** tab → **New repository variable**
   - Name: `MY_GREETING`
   - Value: e.g. `Hello from a GitHub Actions variable`

3. **Run the workflow**:
   - **Actions** tab → **Secrets Demo** → **Run workflow** (uses `workflow_dispatch`),
     or just push a commit to `main`.

## What to expect

- Before you add the secret, the first run **fails on purpose** with a clear
  message. That is the script telling you the secret/variable is missing.
- After adding both, the run prints the greeting and confirms the secret was
  received with its character length — never the value itself.
- Try editing the script to `echo "$MY_SECRET"` and watch the log show `***`
  instead of the real value: GitHub auto-masks registered secrets. Useful to
  see once, but do not rely on it — treat secrets as write-only.

## Scopes worth trying next

- **Environment secrets**: create an Environment (Settings → Environments),
  attach a secret to it, and add `environment: <name>` to the job. You can add
  protections like required reviewers.
- **Organization secrets**: if you ever move this into an org, secrets can be
  shared across repos.
