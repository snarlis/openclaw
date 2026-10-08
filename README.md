# snarlis/openclaw

Personal OpenClaw setup for this laptop (Windows 10/11).

- Config template lives here: `openclaw.template.json`
- Live config lives outside the repo: `~/.openclaw/openclaw.json`
- Live workspace lives outside the repo: `~/.openclaw/workspace`
- Secrets are **never** committed. API keys live in env (`$env:OPENROUTER_API_KEY`)
  or the local SQLite auth store (`openclaw models auth login`).

Default provider: **OpenRouter** (`openrouter/auto`).

## Prerequisites

- Windows 10/11 (native, no WSL required)
- Node.js 24.16+ or 26.1+ (`node --version`)
- Git + GitHub CLI (`gh`)

One-shot install (winget, may prompt for UAC / admin approval):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-prereqs.ps1
```

Then restart your terminal and verify:

```powershell
node --version   # want v24.x or v26.x
cmd /c "npm --version"
git --version
gh --version
```

## Quick start

1. Copy `.env.example` to `.env` (git-ignored) and paste your key:

   ```powershell
   Copy-Item .env.example .env
   notepad .env
   ```

   Get a key at https://openrouter.ai/keys

2. Run the setup script (copies template -> `~/.openclaw/`, installs CLI, baselines):

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
   ```

   What it does:
   - installs/updates the `openclaw` CLI globally (`npm i -g openclaw`)
   - copies `openclaw.template.json` -> `~/.openclaw/openclaw.json` (backs up existing)
   - seeds `~/.openclaw/workspace` from `workspace/` (does not overwrite existing files)
   - runs `openclaw setup --baseline` + `openclaw doctor --fix` + `openclaw config validate`

3. Authenticate the model (pick one, stored locally — not in the repo):

   ```powershell
   # OAuth browser flow (preferred where available)
   openclaw onboard --auth-choice openrouter-oauth

   # ...or API key (paste from https://openrouter.ai/keys)
   openclaw onboard --auth-choice openrouter-api-key
   # or: openclaw models auth login --provider openrouter --method api-key
   ```

4. Start the Gateway:

   ```powershell
   openclaw gateway
   # dashboard: http://127.0.0.1:18789/
   # TUI: openclaw
   # health: openclaw health
   # validate: openclaw config validate
   ```

5. (Optional) Pin a concrete model instead of `openrouter/auto`:

   ```powershell
   openclaw models set openrouter/anthropic/claude-sonnet-4-6
   ```

## Repo layout

```text
.
├── openclaw.template.json   # canonical config template (no secrets)
├── .env.example             # env var names only (copy to .env, never commit .env)
├── workspace/               # seed files for ~/.openclaw/workspace
│   ├── SOUL.md
│   ├── USER.md
│   ├── BOOTSTRAP.md
│   └── memory/
├── scripts/
│   ├── install-prereqs.ps1  # winget: Node LTS 24, Git, GitHub CLI
│   └── setup.ps1            # install CLI + seed ~/.openclaw + baseline + doctor
├── package.json             # convenience scripts only
└── docs/
    └── SETUP-NOTES.md
```

## Updating

```powershell
cmd /c "npm install -g openclaw@latest"
openclaw update   # or: openclaw update --channel stable
openclaw doctor --fix
```

Upstream docs: https://docs.openclaw.ai/start/setup

## Security

- `.env` is git-ignored. Never paste keys into `*.json`, `*.md`, or transcripts.
- Before committing, run: `git status --short` and confirm no `.env`, `secrets.json`,
  or `~/.openclaw/credentials` paths show up.
- To check for accidental secrets: `git diff --cached --stat` + search for `sk-or-`.
