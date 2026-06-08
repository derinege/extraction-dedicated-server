# INSTALL_SCRIPT_VERSION=3
# Electron binary eksik/bozuk ise yeniden indirir (mirror + retry + zip fallback).
param(
  [string]$InstallDir = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$ElectronVersion = "35.1.5"

if (-not $InstallDir) {
  $InstallDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$panel = Join-Path $InstallDir "Tools\dedicated-server-manager"
$electronPkg = Join-Path $panel "node_modules\electron"
$electronExe = Join-Path $electronPkg "dist\electron.exe"
$pathTxt = Join-Path $electronPkg "path.txt"
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
  $nodeVer = (node -v) -replace "^v", ""
  $major = [int]($nodeVer.Split(".")[0])
  Write-Log "Node: v$nodeVer  npm: $(npm -v)" "DarkGray"
  if ($major -ge 24) {
    Write-Log "UYARI: Node v$nodeVer desteklenmeyebilir. nodejs.org -> LTS v22 kur, PC restart." "Yellow"
  }
}

function Test-ElectronInstalled {
  return (Test-Path $pathTxt) -and (Test-Path $electronExe)
}

function Test-ElectronHealthy {
  if (-not (Test-ElectronInstalled)) { return $false }
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

function Remove-ElectronInstall {
  Write-Log "Electron siliniyor (temiz kurulum)..." "Yellow"
  $targets = @(
    $electronPkg,
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
  $installJs = Join-Path $electronPkg "install.js"
  if (-not (Test-Path $installJs)) { return $false }
  Write-Log "Electron binary indiriliyor (install.js)..." "DarkGray"
  $env:force_no_cache = "true"
  & node $installJs
  $code = $LASTEXITCODE
  Remove-Item Env:force_no_cache -ErrorAction SilentlyContinue
  if ($code -ne 0) {
    Write-Log "  install.js cikis kodu: $code" "Yellow"
    return $false
  }
  return (Test-ElectronInstalled)
}

function Install-ElectronFromZip($label, $mirrorBase) {
  Write-Log "ZIP fallback: $label" "Cyan"
  if (-not (Test-Path (Join-Path $electronPkg "package.json"))) {
    npm install "electron@$ElectronVersion" --save-dev --no-audit --no-fund --ignore-scripts
  }

  $distDir = Join-Path $electronPkg "dist"
  $zipName = "electron-v$ElectronVersion-win32-x64.zip"
  if ($mirrorBase) {
    $url = "$mirrorBase$ElectronVersion/$zipName"
  } else {
    $url = "https://github.com/electron/electron/releases/download/v$ElectronVersion/$zipName"
  }

  $tmpZip = Join-Path $env:TEMP $zipName
  Write-Log "  Indiriliyor: $url" "DarkGray"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri $url -OutFile $tmpZip -UseBasicParsing

  if (Test-Path $distDir) {
    Remove-Item -Recurse -Force $distDir
  }
  New-Item -ItemType Directory -Path $distDir -Force | Out-Null
  Expand-Archive -Path $tmpZip -DestinationPath $distDir -Force
  Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue

  Set-Content -Path $pathTxt -Value "electron.exe" -NoNewline -Encoding ASCII
  Set-Content -Path (Join-Path $distDir "version") -Value "v$ElectronVersion" -NoNewline -Encoding ASCII

  return (Test-ElectronInstalled)
}

function Try-InstallElectron($label, $mirror) {
  Write-Log "Deneme: $label" "Cyan"
  if ($mirror) {
    $env:ELECTRON_MIRROR = $mirror
    Write-Log "  Mirror: $mirror" "DarkGray"
  } else {
    Remove-Item Env:ELECTRON_MIRROR -ErrorAction SilentlyContinue
  }

  if (Test-Path $electronPkg) {
    Remove-Item -Recurse -Force $electronPkg -ErrorAction SilentlyContinue
  }

  npm install "electron@$ElectronVersion" --save-dev --foreground-scripts --no-audit --no-fund --force
  if (Test-ElectronInstalled) { return $true }
  if (Run-ElectronPostinstall) { return $true }
  return $false
}

Write-Log "========================================" "Cyan"
Write-Log "  FIX ELECTRON" "Cyan"
Write-Log "========================================" "Cyan"
Write-Log "Klasor: $InstallDir"
Write-Log "Log: $logFile" "DarkGray"

if ($InstallDir -match "OneDrive") {
  Write-Log "UYARI: OneDrive klasoru sorun cikarabilir. C:\extraction-server gibi bir yola tasi." "Yellow"
}

Ensure-Node

if ($Force) {
  Remove-ElectronInstall
} elseif (Test-ElectronHealthy) {
  Write-Log "Electron OK: $electronExe" "Green"
  exit 0
} elseif (Test-Path $electronPkg) {
  Write-Log "Electron eksik/bozuk (path.txt veya exe yok), yeniden kuruluyor..." "Yellow"
  Remove-ElectronInstall
}

Ensure-PanelDeps
if (-not $Force) { Clear-ElectronCache }

$npmAttempts = @(
  @{ Label = "npm + GitHub"; Mirror = $null },
  @{ Label = "npm + npmmirror CDN"; Mirror = "https://cdn.npmmirror.com/binaries/electron/" },
  @{ Label = "npm + npmmirror"; Mirror = "https://npmmirror.com/mirrors/electron/" }
)

$ok = $false
foreach ($a in $npmAttempts) {
  try {
    if (Try-InstallElectron $a.Label $a.Mirror) {
      $ok = $true
      break
    }
  } catch {
    Write-Log "  Hata: $($_.Exception.Message)" "Yellow"
  }
}

if (-not $ok) {
  $zipAttempts = @(
    @{ Label = "ZIP GitHub"; Mirror = $null },
    @{ Label = "ZIP npmmirror"; Mirror = "https://cdn.npmmirror.com/binaries/electron/" }
  )
  foreach ($z in $zipAttempts) {
    try {
      if (Install-ElectronFromZip $z.Label $z.Mirror) {
        $ok = $true
        break
      }
    } catch {
      Write-Log "  ZIP hata: $($_.Exception.Message)" "Yellow"
    }
  }
}

if ($ok -and (Test-ElectronHealthy)) {
  Write-Log ""
  Write-Log "Electron kuruldu!" "Green"
  Write-Log "Simdi BASLAT-SERVER.bat calistir." "Yellow"
  exit 0
}

Write-Log ""
Write-Log "HATA: Electron hala kurulamadi." "Red"
Write-Log "  1) Node.js LTS v22 kur (v24 kaldir): https://nodejs.org" "Yellow"
Write-Log "  2) TEMIZLE-ELECTRON.bat -> Yonetici olarak calistir" "Yellow"
Write-Log "  3) Antivirus gecici kapat" "Yellow"
Write-Log "  4) electron-install.log dosyasini Derin'e at" "Yellow"
exit 1
