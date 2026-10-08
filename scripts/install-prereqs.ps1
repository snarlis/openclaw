#Requires -Version 5.1
<#
  install-prereqs.ps1 — install Node LTS 24, Git, GitHub CLI via winget.
  May trigger a UAC prompt (machine-wide installs). Accept it, then restart
  your terminal when done.
#>
$ErrorActionPreference = "Stop"

function Test-Cmd($name) { $null -ne (Get-Command $name -ErrorAction SilentlyContinue) }

function Install-Winget($id, $label) {
  if (Test-Cmd ($id -replace '^Git\.Git$', 'git' -replace '^GitHub\.cli$', 'gh' -replace '^OpenJS\..*$', 'node'))) {
    # cheap pre-check; real check below per tool
  }
  Write-Host "==> winget install $id ($label) ..." -ForegroundColor Cyan
  winget install --id $id --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity --scope machine
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "machine-scope install failed for $id (exit $LASTEXITCODE), retrying user scope..."
    winget install --id $id --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity --scope user
    if ($LASTEXITCODE -ne 0) { throw "winget install failed for $id" }
  }
}

Write-Host "Checking prerequisites..." -ForegroundColor Green

# Node 24.16+ required. winget LTS currently ships 24.x.
$nodeOk = $false
if (Test-Cmd "node") {
  $v = (node --version) 2>$null
  Write-Host "node: $v"
  if ($v -match 'v(\d+)\.(\d+)\.') {
    $major = [int]$Matches[1]; $minor = [int]$Matches[2]
    if (($major -eq 24 -and $minor -ge 16) -or ($major -eq 26) -or ($major -gt 26)) { $nodeOk = $true }
  }
}
if (-not $nodeOk) { Install-Winget "OpenJS.NodeJS.LTS" "Node.js LTS 24" }
else { Write-Host "node OK, skipping install." -ForegroundColor Green }

if (-not (Test-Cmd "git")) { Install-Winget "Git.Git" "Git" }
else { Write-Host ("git OK: " + (git --version)) -ForegroundColor Green }

if (-not (Test-Cmd "gh")) { Install-Winget "GitHub.cli" "GitHub CLI" }
else { Write-Host ("gh OK: " + (gh --version | Select-Object -First 1)) -ForegroundColor Green }

Write-Host ""
Write-Host "Done. If Node/Git/gh were just installed, RESTART your terminal," -ForegroundColor Yellow
Write-Host "then run: powershell -ExecutionPolicy Bypass -File scripts/setup.ps1" -ForegroundColor Yellow
