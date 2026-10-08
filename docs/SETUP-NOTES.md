# Setup notes (Windows laptop, Oct 2026)

Environment at scaffold time:

- OS: Windows 10/11, native (no WSL)
- `node --version` was v22.17.1 → needs upgrade to 24.16+ / 26.1+
- `npm` 10.9.2 via `cmd /c` (`npm.ps1` blocked by default ExecutionPolicy)
- `git`, `gh` were missing → installed via winget (`Git.Git`, `GitHub.cli`)
- `openclaw` CLI not installed → `npm i -g openclaw` in `scripts/setup.ps1`

Why the repo does NOT contain live state:

- Upstream guidance: keep tailoring in `~/.openclaw/openclaw.json` +
  `~/.openclaw/workspace` so repo updates don't touch personal config.
- This repo holds **templates + seeds + scripts**. `scripts/setup.ps1`
  copies them into `~/.openclaw/` on each machine.

OpenRouter specifics:

- Default model ref: `openrouter/auto`.
- Auth is interactive and local-only:
  `openclaw onboard --auth-choice openrouter-oauth` (browser PKCE), or
  `openclaw onboard --auth-choice openrouter-api-key` (key from
  https://openrouter.ai/keys), or
  `openclaw models auth login --provider openrouter --method api-key`.
- Key is stored in the local SQLite auth store / env, never in git.

Troubleshooting:

- `npm.ps1 cannot be loaded` → use `cmd /c "npm ..."` (`npm.cmd ...`) or
  `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
- Same block for `openclaw.ps1` → use `openclaw.cmd ...` in PowerShell.
- `winget` msstore prompt fails headless → always pass
  `--source winget --accept-source-agreements --disable-interactivity`.
- UAC prompt on install → accept, then restart the terminal
  (PATH / npm prefix refresh: `C:\Users\<you>\AppData\Roaming\npm`).
- Gateway port clash → `openclaw config set gateway.port 19001`.
- Never `npm install -g openclaw` while the Gateway service runs on Windows
  (file locks can half-replace `dist/`, then the Gateway crashes with
  `ERR_MODULE_NOT_FOUND` for hashed chunks). Stop first:
  `schtasks /End /TN "OpenClaw Gateway"`, reinstall, then
  `openclaw.cmd gateway restart`.
- If startup stalls right after `loading whatsapp ...`, disable it temporarily
  (`openclaw plugins disable whatsapp` +
  `openclaw config set channels.whatsapp.enabled false`), restart, then
  re-pair with `openclaw channels add`.
