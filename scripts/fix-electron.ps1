# INSTALL_SCRIPT_VERSION=3
# Electron binary eksik/bozuk ise yeniden indirir (mirror + retry).
param(
  [string]$InstallDir = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"
if (-not $InstallDir) {
  $InstallDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$panel = Join-Path $InstallDir "Tools\dedicated-server-manager"
$electronExe = Join-Path $panel "node_modules\electron\dist\electron.exe"
$logFile = Join-Path $InstallDir "electron-install.log"

function Write-Log($msg, $color = "White") {
  $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
  Add-Content -Path $logFile -Value $line -Encoding UTF8
  Write-Host $msg -ForegroundColor $color
}

function Ensure-Node {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    Write-Log "HATA: Node.js yok. https://nodejs.org LTS kur, PC restart." "Red"
    exit 1
  }
  Write-Log "Node: $(node -v)  npm: $(npm -v)" "DarkGray"
}

function Remove-ElectronInstall {
  Write-Log "Electron siliniyor (temiz kurulum)..." "Yellow"
  $targets = @(
    (Join-Path $panel "node_modules\electron"),
    (Join-Path $panel "node_modules\.bin\electron.cmd"),
    (Join-Path $panel "node_modules\.bin\electron.ps1")
  )
  foreach ($t in $targets) {
    if (Test-Path $t) {
      Remove-Item -Recurse -Force $t -ErrorAction SilentlyContinue
      Write-Log "  Silindi: $t" "DarkGray"
    }
  }
  Clear-ElectronCache
}

function Test-ElectronHealthy {
  if (-not (Test-Path $electronExe)) { return $false }
  try {
    $v = & $electronExe --version 2>&1
    return ($LASTEXITCODE -eq 0 -and $v)
  } catch {
    return $false
  }
}

function Clear-ElectronCache {
  $paths = @(
    (Join-Path $env:LOCALAPPDATA "electron\Cache"),
    (Join-Path $env:USERPROFILE ".cache\electron")
  )
  foreach ($p in $paths) {
    if (Test-Path $p) {
      Write-Log "Cache temizleniyor: $p" "DarkGray"
      Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue
    }
  }
}

function Ensure-PanelDeps {
  if (-not (Test-Path (Join-Path $panel "package.json"))) {
    Write-Log "HATA: Panel klasoru bulunamadi: $panel" "Red"
    exit 1
  }
  Set-Location $panel
  $env:NODE_ENV = "development"
  if (-not (Test-Path "node_modules")) {
    Write-Log "node_modules yok, panel bagimliliklari kuruluyor..." "Yellow"
    npm install --include=dev --foreground-scripts --no-audit --no-fund
  }
}

function Run-ElectronPostinstall {
  $installJs = Join-Path $panel "node_modules\electron\install.js"
  if (-not (Test-Path $installJs)) { return }
  Write-Log "Electron postinstall calistiriliyor..." "DarkGray"
  & node $installJs
}

function Try-InstallElectron($label, $mirror) {
  Write-Log "Deneme: $label" "Cyan"
  if ($mirror) {
    $env:ELECTRON_MIRROR = $mirror
    Write-Log "  Mirror: $mirror" "DarkGray"
  } else {
    Remove-Item Env:ELECTRON_MIRROR -ErrorAction SilentlyContinue
  }

  if (Test-Path (Join-Path $panel "node_modules\electron")) {
    Remove-Item -Recurse -Force (Join-Path $panel "node_modules\electron") -ErrorAction SilentlyContinue
  }

  npm install electron@35.1.5 --save-dev --foreground-scripts --no-audit --no-fund --force
  if (-not (Test-Path $electronExe)) {
    Run-ElectronPostinstall
  }
  return (Test-Path $electronExe)
}

Write-Log "========================================" "Cyan"
Write-Log "  FIX ELECTRON" "Cyan"
Write-Log "========================================" "Cyan"
Write-Log "Klasor: $InstallDir"
Write-Log "Log: $logFile" "DarkGray"

if ($InstallDir -match "OneDrive") {
  Write-Log "UYARI: OneDrive klasoru antivirus/sync sorunu cikarabilir. C:\extraction-server gibi bir yola tasi." "Yellow"
}

Ensure-Node

if ($Force) {
  Remove-ElectronInstall
} elseif (Test-ElectronHealthy) {
  Write-Log "Electron zaten kurulu: $electronExe" "Green"
  exit 0
} elseif (Test-Path $electronExe) {
  Write-Log "Electron dosyasi var ama bozuk, yeniden kuruluyor..." "Yellow"
  Remove-ElectronInstall
}

Ensure-PanelDeps
if (-not $Force) { Clear-ElectronCache }

$attempts = @(
  @{ Label = "GitHub (varsayilan)"; Mirror = $null },
  @{ Label = "npmmirror CDN"; Mirror = "https://cdn.npmmirror.com/binaries/electron/" },
  @{ Label = "npmmirror mirror"; Mirror = "https://npmmirror.com/mirrors/electron/" }
)

$ok = $false
foreach ($a in $attempts) {
  try {
    if (Try-InstallElectron $a.Label $a.Mirror) {
      $ok = $true
      break
    }
  } catch {
    Write-Log "  Hata: $($_.Exception.Message)" "Yellow"
  }
}

if ($ok) {
  Write-Log ""
  Write-Log "Electron kuruldu!" "Green"
  Write-Log "Simdi BASLAT-SERVER.bat calistir." "Yellow"
  exit 0
}

Write-Log ""
Write-Log "HATA: Electron hala kurulamadi." "Red"
Write-Log "  1) Klasoru OneDrive disina tasi (ornek: C:\extraction-server)" "Yellow"
Write-Log "  2) FIX-ELECTRON.bat sag tik -> Yonetici olarak calistir" "Yellow"
Write-Log "  3) Antivirus gecici kapat, tekrar dene" "Yellow"
Write-Log "  4) electron-install.log dosyasini Derin'e at" "Yellow"
exit 1
