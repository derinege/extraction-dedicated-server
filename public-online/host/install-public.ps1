# INSTALL_SCRIPT_VERSION=PUBLIC-2
# Public online — Playit.gg (port forward yok).

param(
  [string]$InstallDir = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$HostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PublicOnlineDir = Split-Path -Parent $HostDir
if (-not $InstallDir) {
  $InstallDir = Split-Path -Parent $PublicOnlineDir
}

$RepoZipUrl = "https://github.com/derinege/extraction-dedicated-server/archive/refs/heads/main.zip"
$GameZipUrl = "https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.0-game/game.zip"
$StateFile = Join-Path $InstallDir ".extraction-public-install.json"

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
    Write-Host "2) PC restart, KUR-PUBLIC.bat tekrar" -ForegroundColor Yellow
    exit 1
  }
  Write-Host "Node: $(node -v)  npm: $(npm -v)" -ForegroundColor DarkGray
}

function Download-File($Url, $Dest) {
  Write-Host "  Indiriliyor: $Url" -ForegroundColor DarkGray
  Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
}

function Test-RegistryReady($Dir) {
  return (Test-Path (Join-Path $Dir "node_modules\express\package.json"))
}

function Test-ElectronReady($Dir) {
  $pkg = Join-Path $Dir "node_modules\electron"
  return (
    (Test-Path (Join-Path $pkg "index.js")) -and
    (Test-Path (Join-Path $pkg "cli.js")) -and
    (Test-Path (Join-Path $pkg "path.txt")) -and
    (Test-Path (Join-Path $pkg "dist\electron.exe"))
  )
}

function Test-PanelReady($Dir) {
  $nm = Join-Path $Dir "node_modules"
  if (-not (Test-Path $nm)) { return $false }
  $count = (Get-ChildItem $nm -Directory -ErrorAction SilentlyContinue).Count
  return ($count -gt 5) -and (Test-ElectronReady $Dir)
}

function Invoke-FixElectronPublic($InstallDir, [switch]$Force) {
  $fixScript = Join-Path $HostDir "fix-electron-public.ps1"
  if (-not (Test-Path $fixScript)) { return $false }
  Write-Host "  fix-electron-public.ps1 calistiriliyor..." -ForegroundColor DarkGray
  if ($Force) {
    & $fixScript -InstallDir $InstallDir -Force
  } else {
    & $fixScript -InstallDir $InstallDir
  }
  return ($LASTEXITCODE -eq 0)
}

function Ensure-PlayitConfig($InstallDir) {
  Write-Step "Playit config"
  $example = Join-Path $InstallDir "public-online\playit.config.example.json"
  $target = Join-Path $InstallDir "public-online\playit.config.json"
  if (-not (Test-Path $target)) {
    if (-not (Test-Path $example)) { throw "playit.config.example.json bulunamadi" }
    Copy-Item $example $target
    Write-Host "  Olusturuldu: $target" -ForegroundColor Green
    Write-Host "  Playit tunnel adreslerini bu dosyaya yaz!" -ForegroundColor Yellow
  } else {
    Write-Skip "playit.config.json zaten var"
  }
}

function Ensure-RegistrySecret($InstallDir) {
  Write-Step "Registry secret (guvenlik)"
  $secretDir = Join-Path $InstallDir "public-online\secrets"
  $secretFile = Join-Path $secretDir "registry-secret.txt"
  New-Item -ItemType Directory -Path $secretDir -Force | Out-Null
  if (Test-Path $secretFile) {
    Write-Skip "registry-secret.txt zaten var"
    return
  }
  $bytes = New-Object byte[] 32
  [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $secret = [BitConverter]::ToString($bytes).Replace("-", "").ToLower()
  Set-Content -Path $secretFile -Value $secret -Encoding ASCII -NoNewline
  Write-Host "  OK (public-online\secrets\registry-secret.txt)" -ForegroundColor Green
}

function Add-FirewallLocalOnly {
  Write-Step "Windows Firewall (local 7777, 8787 — Playit icin)"
  $rules = @(
    @{ Name = "Extraction Public Game 7777 TCP"; Protocol = "TCP"; Port = 7777 },
    @{ Name = "Extraction Public Game 7777 UDP"; Protocol = "UDP"; Port = 7777 },
    @{ Name = "Extraction Public Registry 8787"; Protocol = "TCP"; Port = 8787 }
  )
  foreach ($r in $rules) {
    $existing = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
    if ($existing) {
      Write-Skip $r.Name
      continue
    }
    try {
      New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Action Allow -Protocol $r.Protocol -LocalPort $r.Port | Out-Null
      Write-Host "  OK: $($r.Name)" -ForegroundColor Green
    } catch {
      Write-Host "  UYARI: $($r.Name) eklenemedi (yonetici gerekebilir)" -ForegroundColor Yellow
    }
  }
}

function Save-InstallState($InstallDir, $panel, $registry, $gameExe) {
  @{
    installedAt = (Get-Date).ToString("o")
    mode        = "public"
    game        = (Test-Path $gameExe)
    registry    = (Test-RegistryReady $registry)
    panel       = (Test-PanelReady $panel)
  } | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EXTRACTION PUBLIC SERVER KURULUM" -ForegroundColor Cyan
Write-Host "  Playit.gg (PUBLIC — port forward yok)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Repo klasoru: $InstallDir"

Ensure-Node

$panel = Join-Path $InstallDir "public-online\panel"
$registry = Join-Path $InstallDir "Tools\server-registry"
$gameExe = Join-Path $InstallDir "game\ExtractionShooterServer.exe"

if ($Force -or -not (Test-Path (Join-Path $panel "package.json"))) {
  Write-Step "Repo dosyalari (public-online + registry)"
  if (-not (Test-Path (Join-Path $panel "package.json"))) {
    $tmp = Join-Path $env:TEMP "extraction-public-setup"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $repoZip = Join-Path $tmp "repo.zip"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Download-File $RepoZipUrl $repoZip
    Expand-Archive -Path $repoZip -DestinationPath $tmp -Force
    $extracted = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "extraction-dedicated-server*" } | Select-Object -First 1
    if (-not $extracted) { throw "Repo zip acilamadi" }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    foreach ($name in @("public-online", "Tools", "scripts")) {
      $src = Join-Path $extracted.FullName $name
      if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $InstallDir $name) -Recurse -Force
      }
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  OK" -ForegroundColor Green
  }
} else {
  Write-Skip "public-online/panel zaten var"
}

if (-not (Test-Path (Join-Path $panel "package.json"))) {
  throw "public-online\panel bulunamadi. Zip veya git ile tam repo al."
}

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
  Write-Step "Public panel (npm install + Electron)"
  Set-Location $panel
  $env:NODE_ENV = "development"
  $panelNm = Join-Path $panel "node_modules"
  if (-not (Test-Path $panelNm)) {
    npm install --include=dev --foreground-scripts --no-audit --no-fund
  }
  if (-not (Test-ElectronReady $panel)) {
    if (-not (Invoke-FixElectronPublic $InstallDir)) {
      if (-not (Invoke-FixElectronPublic $InstallDir -Force)) {
        throw "Electron kurulamadi. Yonetici olarak tekrar dene."
      }
    }
  }
  if (-not (Test-PanelReady $panel)) {
    throw "Public panel kurulamadi."
  }
  Write-Host "  OK" -ForegroundColor Green
} else {
  Write-Skip "Public panel + Electron zaten kurulu"
}

Add-FirewallLocalOnly
Ensure-PlayitConfig $InstallDir
Ensure-RegistrySecret $InstallDir
Save-InstallState $InstallDir $panel $registry $gameExe

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  HAZIR (PLAYIT MODE)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "1) https://playit.gg agent kur + 2 tunnel (8787 TCP, 7777 TCP+UDP)" -ForegroundColor Yellow
Write-Host "2) public-online\playit.config.json doldur" -ForegroundColor Yellow
Write-Host "3) Calistir: public-online\BASLAT-PUBLIC.bat -> START" -ForegroundColor Yellow
Write-Host "4) CLIENT REGISTRY URL oyunculara (docs\PLAYIT-SETUP.md)" -ForegroundColor Yellow
Write-Host "5) Guncel game build gerekir (EXTRACTION_PUBLIC_PORT + registry secret)" -ForegroundColor Yellow
Write-Host ""

Set-Location $InstallDir
