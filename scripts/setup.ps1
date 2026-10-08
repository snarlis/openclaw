#Requires -Version 5.1
<#
  setup.ps1 -- install openclaw CLI, seed ~/.openclaw from this repo, baseline + doctor.
  Safe to re-run: never overwrites existing ~/.openclaw files without backup,
  never writes secrets.
#>
param(
  [switch]$Restore  # overwrite ~/.openclaw/openclaw.json from the repo template (backup first)
)
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$OpenClawDir = Join-Path $HOME ".openclaw"
$TargetConfig = Join-Path $OpenClawDir "openclaw.json"
$TargetWorkspace = Join-Path $OpenClawDir "workspace"
$TemplateConfig = Join-Path $RepoRoot "openclaw.template.json"
$SeedWorkspace = Join-Path $RepoRoot "workspace"

# Refresh PATH from registry so fresh installs (node/git/gh) resolve.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "Repo: $RepoRoot"

# 1. Node version gate (openclaw needs 24.16+ / 26.1+)
$nodeRaw = (& node --version) 2>$null
if (-not $nodeRaw) { throw "node not found. Run scripts/install-prereqs.ps1 first." }
Write-Host "node: $nodeRaw"
if ($nodeRaw -match 'v(\d+)\.(\d+)\.') {
  $major = [int]$Matches[1]; $minor = [int]$Matches[2]
  $ok = (($major -eq 24 -and $minor -ge 16) -or ($major -ge 26))
  if (-not $ok) { throw "node $nodeRaw too old. Need 24.16+ or 26.1+. Run scripts/install-prereqs.ps1." }
}

# 2. Install / update openclaw CLI globally.
# NOTE: call npm.cmd directly (npm.ps1 is blocked by default ExecutionPolicy).
$npmCmd = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if (-not $npmCmd) { throw "npm.cmd not found on PATH. Restart the terminal and retry." }
Write-Host "==> installing openclaw CLI (npm i -g openclaw) ..."
& $npmCmd install -g openclaw
if ($LASTEXITCODE -ne 0) { throw "npm install -g openclaw failed (exit $LASTEXITCODE)" }

# Re-resolve PATH so the fresh openclaw shim is found.
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + (Join-Path $env:APPDATA "npm")
$openclawCmd = (Get-Command openclaw -ErrorAction SilentlyContinue).Source
if (-not $openclawCmd) {
  $guess = Join-Path $env:APPDATA "npm\openclaw.cmd"
  if (Test-Path $guess) { $openclawCmd = $guess } else { throw "openclaw not found on PATH after install." }
}
& $openclawCmd --version

# 2b. Install non-stock plugins from plugins.txt (idempotent: warns, does not throw).
$plugFile = Join-Path $RepoRoot "plugins.txt"
if (Test-Path $plugFile) {
  Get-Content $plugFile | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' } | ForEach-Object {
    $spec = $_.Trim()
    Write-Host "==> installing plugin $spec ..."
    & $openclawCmd plugins install $spec --accept-capabilities --acknowledge-install-policy-warning
    if ($LASTEXITCODE -ne 0) { Write-Host "plugin install exited $LASTEXITCODE for $spec (may already be installed)" }
  }
} else {
  Write-Host "no plugins.txt -- skipping plugin installs"
}

# 3. Seed ~/.openclaw
New-Item -ItemType Directory -Force -Path $OpenClawDir | Out-Null
if (($Restore -or -not (Test-Path $TargetConfig))) {
  if (Test-Path $TargetConfig) {
    $bak = "$TargetConfig.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $TargetConfig $bak
    Write-Host "backed up existing config -> $bak"
  }
  Copy-Item $TemplateConfig $TargetConfig
  Write-Host "wrote $TargetConfig from repo template"
} else {
  Write-Host "$TargetConfig exists -- leaving in place (re-run with -Restore to overwrite from template)"
}

if (-not (Test-Path $TargetWorkspace)) {
  New-Item -ItemType Directory -Force -Path $TargetWorkspace | Out-Null
}
# copy seed files only if missing (never clobber personal workspace)
Get-ChildItem -Path $SeedWorkspace -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Substring($SeedWorkspace.Length).TrimStart('\', '/')
  $dest = Join-Path $TargetWorkspace $rel
  if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
    Copy-Item $_.FullName $dest
    Write-Host "seeded workspace/$rel"
  }
}

# 4. Load .env if present (local key, never committed)
$dotenv = Join-Path $RepoRoot ".env"
if (Test-Path $dotenv) {
  Get-Content $dotenv | ForEach-Object {
    $line = $_
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
      $k = $Matches[1]
      $v = $Matches[2].Trim(@('"', "'"))
      if ($v -ne "" -and $v -notlike '*PASTE_HERE*') { Set-Item -Path "env:$k" -Value $v }
    }
  }
  Write-Host "loaded .env into process env (this shell only)"
} else {
  Write-Host ".env not found -- copy .env.example to .env and add OPENROUTER_API_KEY"
}

# 5. Baseline + doctor + validate (non-interactive, no secrets written)
Write-Host "==> openclaw setup --baseline ..."
& $openclawCmd setup --baseline
Write-Host "==> openclaw doctor --fix ..."
& $openclawCmd doctor --fix
Write-Host "==> openclaw config validate ..."
& $openclawCmd config validate

Write-Host ""
Write-Host "Next:"
Write-Host "  1. openclaw onboard --auth-choice openrouter-oauth   # or ...-api-key"
Write-Host "  2. openclaw health"
Write-Host "  3. openclaw gateway  # dashboard http://127.0.0.1:18789/"
