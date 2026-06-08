# INSTALL_SCRIPT_VERSION=3
# Tek script - Git / GitHub CLI gerekmez.
# Tekrar calistirinca SADECE eksik parcalari kurar.

param(
  [string]$InstallDir = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $InstallDir) { $InstallDir = $RepoRoot }

$RepoZipUrl = "https://github.com/derinege/extraction-dedicated-server/archive/refs/heads/main.zip"
$GameZipUrl = "https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.0-game/game.zip"
$StateFile = Join-Path $InstallDir ".extraction-install.json"

function Write-Step($msg) {
  Write-Host ""
  Write-Host ">> $msg" -ForegroundColor Cyan
}

function Write-Skip($msg) {
  Write-Host "  [ATLANDI] $msg" -ForegroundColor DarkGray
}

function Ensure-Node {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    Write-Host ""
    Write-Host "HATA: Node.js yok." -ForegroundColor Red
    Write-Host "1) https://nodejs.org LTS kur" -ForegroundColor Yellow
    Write-Host "2) PC restart, KUR.bat tekrar" -ForegroundColor Yellow
    exit 1
  }
  Write-Host "Node: $(node -v)  npm: $(npm -v)" -ForegroundColor DarkGray
}

function Download-File($Url, $Dest) {
  Write-Host "  Indiriliyor: $Url" -ForegroundColor DarkGray
  try {
    Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
  } catch {
    Write-Host "Indirme basarisiz." -ForegroundColor Red
    throw
  }
}

function Test-RegistryReady($Dir) {
  return (Test-Path (Join-Path $Dir "node_modules\express\package.json"))
}

function Test-PanelReady($Dir) {
  $electronExe = Join-Path $Dir "node_modules\electron\dist\electron.exe"
  return (Test-Path $electronExe)
}

function Save-InstallState($InstallDir, $panel, $registry, $gameExe) {
  $state = @{
    installedAt = (Get-Date).ToString("o")
    game        = (Test-Path $gameExe)
    registry    = (Test-RegistryReady $registry)
    panel       = (Test-PanelReady $panel)
  }
  $state | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EXTRACTION DEDICATED SERVER KURULUM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Klasor: $InstallDir"
if ($Force) { Write-Host "Mod: TUMUNU YENIDEN KUR (-Force)" -ForegroundColor Yellow }

Ensure-Node

$panel = Join-Path $InstallDir "Tools\dedicated-server-manager"
$registry = Join-Path $InstallDir "Tools\server-registry"
$gameExe = Join-Path $InstallDir "game\ExtractionShooterServer.exe"

if ($Force -or -not (Test-Path $panel)) {
  Write-Step "Panel dosyalari"
  if (Test-Path $panel) {
    Write-Host "  Force: panel dosyalari korunuyor" -ForegroundColor DarkGray
  }
  if (-not (Test-Path $panel)) {
    $tmp = Join-Path $env:TEMP "extraction-server-setup"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $repoZip = Join-Path $tmp "repo.zip"
    Download-File $RepoZipUrl $repoZip
    Expand-Archive -Path $repoZip -DestinationPath $tmp -Force
    $extracted = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "extraction-dedicated-server*" } | Select-Object -First 1
    if (-not $extracted) { throw "Repo zip acilamadi" }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Get-ChildItem -Path $extracted.FullName | Where-Object { $_.Name -ne "scripts" } | ForEach-Object {
      Copy-Item -Path $_.FullName -Destination $InstallDir -Recurse -Force
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  OK" -ForegroundColor Green
  }
} else {
  Write-Skip "Repo dosyalari zaten var"
}

if (-not (Test-Path $panel)) { throw "Tools\dedicated-server-manager bulunamadi: $InstallDir" }

if ($Force) {
  Remove-Item -Force $gameExe -ErrorAction SilentlyContinue
}

if (-not (Test-Path $gameExe)) {
  Write-Step "Server binary (game.zip ~335 MB)"
  $gameZip = Join-Path $InstallDir "game.zip"
  Download-File $GameZipUrl $gameZip
  Expand-Archive -Path $gameZip -DestinationPath $InstallDir -Force
  Remove-Item $gameZip -Force -ErrorAction SilentlyContinue
  if (-not (Test-Path $gameExe)) { throw "game\ExtractionShooterServer.exe olusmadi" }
  Write-Host "  OK" -ForegroundColor Green
} else {
  Write-Skip "Server binary zaten var"
}

if ($Force -and (Test-Path (Join-Path $registry "node_modules"))) {
  Remove-Item -Recurse -Force (Join-Path $registry "node_modules")
}

if (-not (Test-RegistryReady $registry)) {
  Write-Step "Registry (npm install)"
  Set-Location $registry
  npm install --omit=dev --no-audit --no-fund
  Write-Host "  OK" -ForegroundColor Green
} else {
  Write-Skip "Registry npm zaten kurulu"
}

if ($Force) {
  Remove-Item -Recurse -Force (Join-Path $panel "node_modules") -ErrorAction SilentlyContinue
}

if (-not (Test-PanelReady $panel)) {
  Write-Step "Panel (npm install + Electron)"
  Set-Location $panel
  $env:NODE_ENV = "development"
  if (-not (Test-Path "node_modules")) {
    npm install --include=dev --foreground-scripts --no-audit --no-fund
  }
  $electronExe = Join-Path $panel "node_modules\electron\dist\electron.exe"
  if (-not (Test-Path $electronExe)) {
    Write-Host "  Electron eksik, indiriliyor (~150 MB)..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force (Join-Path $panel "node_modules\electron") -ErrorAction SilentlyContinue
    npm install electron@35.1.5 --save-dev --foreground-scripts --no-audit --no-fund
  }
  if (-not (Test-Path $electronExe)) {
    throw "Electron kurulamadi. FIX-ELECTRON.bat calistir."
  }
  Write-Host "  OK" -ForegroundColor Green
} else {
  Write-Skip "Panel + Electron zaten kurulu"
}

Save-InstallState $InstallDir $panel $registry $gameExe

$startBat = Join-Path $InstallDir "BASLAT-SERVER.bat"
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  HAZIR" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Calistir: $startBat" -ForegroundColor Yellow
Write-Host "Panelde START DEDICATED SERVER" -ForegroundColor Yellow
Write-Host ""

Set-Location $InstallDir
