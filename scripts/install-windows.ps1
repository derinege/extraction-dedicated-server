# INSTALL_SCRIPT_VERSION=4
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
$GameZipUrl = "https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.1-game/game.zip"
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

function Ensure-FixElectronScript($InstallDir) {
  $scriptDir = Join-Path $InstallDir "scripts"
  $dest = Join-Path $scriptDir "fix-electron.ps1"
  $ver = "INSTALL_SCRIPT_VERSION=4"
  New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
  if ((Test-Path $dest) -and ((Get-Content $dest -Raw) -match [regex]::Escape($ver)) -and ((Get-Content $dest -Raw) -notmatch 'Run-NpmLogged\(\$args\)')) {
    Write-Skip "fix-electron.ps1 guncel"
    return
  }
  $urls = @(
    "https://raw.githubusercontent.com/derinege/extraction-dedicated-server/main/scripts/fix-electron.ps1",
    ("https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/scripts/fix-electron.ps1?v=" + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
  )
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  foreach ($u in $urls) {
    try {
      Write-Host "  fix-electron.ps1 indiriliyor..." -ForegroundColor DarkGray
      Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing
      $t = [IO.File]::ReadAllText($dest).TrimStart([char]0xFEFF)
      [IO.File]::WriteAllText($dest, $t, (New-Object Text.UTF8Encoding $false))
      if ($t -match [regex]::Escape($ver) -and $t -notmatch 'Run-NpmLogged\(\$args\)') {
        Write-Host "  fix-electron.ps1 OK (v4)" -ForegroundColor Green
        return
      }
    } catch {
      Write-Host "  fix-electron indirme hatasi: $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }
  if (-not (Test-Path $dest)) { throw "fix-electron.ps1 indirilemedi" }
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

function Invoke-FixElectron($InstallDir, [switch]$Force) {
  $fixScript = Join-Path $InstallDir "scripts\fix-electron.ps1"
  if (-not (Test-Path $fixScript)) { return $false }
  Write-Host "  fix-electron.ps1 calistiriliyor..." -ForegroundColor DarkGray
  if ($Force) {
    & $fixScript -InstallDir $InstallDir -Force
  } else {
    & $fixScript -InstallDir $InstallDir
  }
  return ($LASTEXITCODE -eq 0)
}

function Test-TailscaleInstalled {
  $exe = Join-Path ${env:ProgramFiles} "Tailscale\tailscale.exe"
  return (Test-Path $exe)
}

function Install-Tailscale {
  if (Test-TailscaleInstalled) {
    Write-Skip "Tailscale zaten kurulu"
    return
  }
  Write-Step "Tailscale (farkli evden baglanti - otomatik)"
  $ok = $false
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    try {
      Write-Host "  winget ile kuruluyor..." -ForegroundColor DarkGray
      & winget install -e --id Tailscale.Tailscale --accept-package-agreements --accept-source-agreements --silent
      if ($LASTEXITCODE -eq 0) { $ok = $true }
    } catch {
      Write-Host "  winget basarisiz, MSI deneniyor..." -ForegroundColor DarkGray
    }
  }
  if (-not $ok) {
    $msi = Join-Path $env:TEMP "tailscale-setup.msi"
    Download-File "https://pkgs.tailscale.com/stable/tailscale-setup-full-latest-amd64.msi" $msi
    Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet" -Wait
    $ok = Test-TailscaleInstalled
  }
  if ($ok) {
    Write-Host "  OK" -ForegroundColor Green
    $tsExe = Join-Path ${env:ProgramFiles} "Tailscale\tailscale.exe"
    if (Test-Path $tsExe) {
      Start-Process $tsExe -ErrorAction SilentlyContinue
      Write-Host "  Tailscale acildi - 1 kere Google/Microsoft ile giris yap" -ForegroundColor Yellow
    }
  } else {
    Write-Host "  UYARI: Tailscale kurulamadi. https://tailscale.com/download/windows" -ForegroundColor Yellow
  }
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
Ensure-FixElectronScript $InstallDir
Install-Tailscale

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

  $panelNm = Join-Path $panel "node_modules"
  if (Test-Path $panelNm) {
    $nmCount = (Get-ChildItem $panelNm -Directory -ErrorAction SilentlyContinue).Count
    if ($nmCount -lt 10 -or -not (Test-ElectronReady $panel)) {
      Write-Host "  node_modules eksik/bozuk ($nmCount paket), yeniden kuruluyor..." -ForegroundColor Yellow
      Remove-Item -Recurse -Force $panelNm -ErrorAction SilentlyContinue
    }
  }

  if (-not (Test-Path $panelNm)) {
    Write-Host "  npm install (panel)..." -ForegroundColor DarkGray
    npm install --include=dev --foreground-scripts --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) {
      Write-Host "  npm install uyarisi (exit $LASTEXITCODE), fix-electron ile devam..." -ForegroundColor Yellow
    }
  }

  if (-not (Test-ElectronReady $panel)) {
    Write-Host "  Electron tam degil, fix-electron calistiriliyor (~150 MB)..." -ForegroundColor Yellow
    if (-not (Invoke-FixElectron $InstallDir)) {
      Write-Host "  Ilk deneme basarisiz, Force ile tekrar..." -ForegroundColor Yellow
      if (-not (Invoke-FixElectron $InstallDir -Force)) {
        throw "Electron kurulamadi. TEMIZLE-ELECTRON.bat calistir, log: extraction-debug.log"
      }
    }
  }

  if (-not (Test-PanelReady $panel)) {
    throw "Panel kurulamadi. DIAGNOSTIK.bat calistir, log gonder."
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
Write-Host "Panelde START -> CLIENT REGISTRY URL kopyala -> Derin'e at" -ForegroundColor Yellow
Write-Host "Tailscale: 1 kere giris yap, Derin'i tailscale'e davet et (veya tersi)" -ForegroundColor Yellow
Write-Host ""

Set-Location $InstallDir
