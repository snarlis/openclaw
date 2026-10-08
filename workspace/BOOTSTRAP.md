# BOOTSTRAP.md — first-run checklist (seeded to ~/.openclaw/workspace)

1. `openclaw config validate` — config must be schema-clean.
2. `openclaw doctor --fix` — repair legacy keys / perms.
3. `openclaw health` — gateway + provider reachability.
4. Auth: `openclaw onboard --auth-choice openrouter-oauth`
   or `openclaw onboard --auth-choice openrouter-api-key`.
5. Pin model (optional): `openclaw models set openrouter/anthropic/claude-sonnet-4-6`.
6. Gateway: `openclaw gateway` → http://127.0.0.1:18789/
