# INSTALL_SCRIPT_VERSION=PUBLIC-1
# Public panel Electron fix — public-online/panel
param(
  [string]$InstallDir = "",
  [switch]$Force
)

$ErrorActionPreference = "Continue"
$ElectronVersion = "35.1.5"

if (-not $InstallDir) {
  $InstallDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$panel = Join-Path $InstallDir "public-online\panel"
$electronPkg = Join-Path $panel "node_modules\electron"
$electronExe = Join-Path $electronPkg "dist\electron.exe"
$pathTxt = Join-Path $electronPkg "path.txt"
$logFile = Join-Path $InstallDir "extraction-debug.log"

function Write-Log($msg, $color = "White") {
  $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
  Add-Content -Path $logFile -Value $line -Encoding UTF8
  Write-Host $msg -ForegroundColor $color
}

function Log-ElectronState($label) {
  Write-Log "--- Electron durum: $label ---" "DarkGray"
  Write-Log "  index.js var: $(Test-Path (Join-Path $electronPkg 'index.js'))" "DarkGray"
  Write-Log "  cli.js var: $(Test-Path (Join-Path $electronPkg 'cli.js'))" "DarkGray"
  Write-Log "  package.json var: $(Test-Path (Join-Path $electronPkg 'package.json'))" "DarkGray"
  Write-Log "  path.txt var: $(Test-Path $pathTxt)" "DarkGray"
  if (Test-Path $pathTxt) { Write-Log "  path.txt: $(Get-Content $pathTxt -Raw)" "DarkGray" }
  Write-Log "  electron.exe var: $(Test-Path $electronExe)" "DarkGray"
  if (Test-Path $electronExe) {
    Write-Log "  electron.exe boyut: $((Get-Item $electronExe).Length) byte" "DarkGray"
  }
  $nm = Join-Path $panel "node_modules"
  if (Test-Path $nm) {
    $count = (Get-ChildItem $nm -Directory -ErrorAction SilentlyContinue).Count
    Write-Log "  node_modules klasor sayisi: $count" "DarkGray"
  }
}

function Run-NpmLogged {
  param([string[]]$NpmArgs)
  Write-Log "  CMD: npm $($NpmArgs -join ' ')" "DarkGray"
  $output = & npm @NpmArgs 2>&1
  foreach ($line in $output) { Write-Log "  npm> $line" "DarkGray" }
  return $LASTEXITCODE
}

function Ensure-Node {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    Write-Log "HATA: Node.js yok. https://nodejs.org kur, PC restart." "Red"
    exit 1
  }
  Write-Log "Node path: $($node.Source)" "DarkGray"
  Write-Log "Node: $(node -v)  npm: $(npm -v)" "DarkGray"
  Write-Log "OS: $([System.Environment]::OSVersion.VersionString)  Admin: $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))" "DarkGray"
}

function Test-ElectronInstalled {
  $cli = Join-Path $electronPkg "cli.js"
  $idx = Join-Path $electronPkg "index.js"
  return (Test-Path $pathTxt) -and (Test-Path $electronExe) -and (Test-Path $cli) -and (Test-Path $idx)
}

function Test-PanelDepsReady {
  $nm = Join-Path $panel "node_modules"
  if (-not (Test-Path $nm)) { return $false }
  $count = (Get-ChildItem $nm -Directory -ErrorAction SilentlyContinue).Count
  return ($count -gt 5) -and (Test-ElectronInstalled)
}

function Test-ElectronHealthy {
  if (-not (Test-ElectronInstalled)) { return $false }
  try {
    $out = & $electronExe --version 2>&1
    $v = ($out | Out-String).Trim()
    Write-Log "  electron --version: $v (exit $LASTEXITCODE)" "DarkGray"
    if ($LASTEXITCODE -eq 0) { return $true }
    $len = (Get-Item $electronExe -ErrorAction SilentlyContinue).Length
    return ($len -gt 50MB)
  } catch {
    Write-Log "  electron --version HATA: $($_.Exception.Message)" "Yellow"
    return $false
  }
}

function Test-ElectronRequire {
  if (-not (Test-Path (Join-Path $panel "node_modules\electron\index.js"))) { return $false }
  Set-Location $panel
  $out = node -e "try{console.log(require('electron'))}catch(e){console.error(e.message);process.exit(1)}" 2>&1
  foreach ($line in $out) { Write-Log "  require> $line" "DarkGray" }
  return ($LASTEXITCODE -eq 0)
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
  if (Test-PanelDepsReady) { return }

  $nm = Join-Path $panel "node_modules"
  if (Test-Path $nm) {
    Write-Log "node_modules eksik/bozuk, tamamen silinip yeniden kuruluyor..." "Yellow"
    Remove-Item -Recurse -Force $nm -ErrorAction SilentlyContinue
  } else {
    Write-Log "node_modules yok, panel bagimliliklari kuruluyor..." "Yellow"
  }

  $code = Run-NpmLogged @("install", "--include=dev", "--foreground-scripts", "--no-audit", "--no-fund", "--loglevel", "verbose")
  if ($code -ne 0) { Write-Log "panel npm install exit: $code" "Yellow" }
}

function Run-ElectronPostinstall {
  $installJs = Join-Path $electronPkg "install.js"
  if (-not (Test-Path $installJs)) { return $false }
  Write-Log "Electron binary indiriliyor (install.js)..." "DarkGray"
  $env:force_no_cache = "true"
  $env:DEBUG = "@electron/get*"
  $out = & node $installJs 2>&1
  foreach ($line in $out) { Write-Log "  install.js> $line" "DarkGray" }
  $code = $LASTEXITCODE
  Remove-Item Env:force_no_cache -ErrorAction SilentlyContinue
  Remove-Item Env:DEBUG -ErrorAction SilentlyContinue
  Log-ElectronState "install.js sonrasi"
  if ($code -ne 0) {
    Write-Log "  install.js cikis kodu: $code" "Yellow"
    return $false
  }
  return (Test-ElectronInstalled)
}

function Install-ElectronFromZip($label, $mirrorBase) {
  Write-Log "ZIP fallback: $label" "Cyan"
  if (-not (Test-Path (Join-Path $electronPkg "cli.js"))) {
    if (Test-Path $electronPkg) {
      Remove-Item -Recurse -Force $electronPkg -ErrorAction SilentlyContinue
    }
    Run-NpmLogged @("install", "electron@$ElectronVersion", "--save-dev", "--no-audit", "--no-fund", "--ignore-scripts")
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
  try {
    Invoke-WebRequest -Uri $url -OutFile $tmpZip -UseBasicParsing
    Write-Log "  ZIP indirildi: $((Get-Item $tmpZip).Length) byte" "DarkGray"
  } catch {
    Write-Log "  ZIP indirme HATA: $($_.Exception.Message)" "Red"
    return $false
  }

  if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
  New-Item -ItemType Directory -Path $distDir -Force | Out-Null
  Expand-Archive -Path $tmpZip -DestinationPath $distDir -Force
  Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue

  Set-Content -Path $pathTxt -Value "electron.exe" -NoNewline -Encoding ASCII
  Set-Content -Path (Join-Path $distDir "version") -Value "v$ElectronVersion" -NoNewline -Encoding ASCII
  Log-ElectronState "ZIP sonrasi"
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

  $code = Run-NpmLogged @("install", "electron@$ElectronVersion", "--save-dev", "--foreground-scripts", "--no-audit", "--no-fund", "--force", "--loglevel", "verbose")
  Log-ElectronState "npm install sonrasi (exit $code)"
  if (Test-ElectronInstalled) { return $true }
  if (Run-ElectronPostinstall) { return $true }
  return $false
}

Write-Log "========================================" "Cyan"
Write-Log "  FIX ELECTRON (PUBLIC PANEL)" "Cyan"
Write-Log "========================================" "Cyan"
Write-Log "Klasor: $InstallDir"
Write-Log "Log: $logFile" "DarkGray"

if ($InstallDir -match "OneDrive") {
  Write-Log "UYARI: OneDrive klasoru sorun cikarabilir. C:\extraction-server gibi bir yola tasi." "Yellow"
}

Ensure-Node
Log-ElectronState "baslangic"

if ($Force) {
  Remove-ElectronInstall
} elseif (Test-ElectronHealthy -and (Test-ElectronRequire)) {
  Write-Log "Electron OK: $electronExe" "Green"
  exit 0
} elseif (Test-Path $electronPkg) {
  Write-Log "Electron eksik/bozuk, yeniden kuruluyor..." "Yellow"
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

Log-ElectronState "final"
$requireOk = Test-ElectronRequire

if ($ok -and (Test-ElectronInstalled) -and $requireOk) {
  Write-Log ""
  Write-Log "Electron kuruldu!" "Green"
  Write-Log "Simdi public-online\BASLAT-PUBLIC.bat calistir." "Yellow"
  exit 0
}

Write-Log ""
Write-Log "HATA: Electron kurulamadi." "Red"
Write-Log "  1) DIAGNOSTIK.bat calistir" "Yellow"
Write-Log "  2) extraction-debug.log dosyasini Derin'e at" "Yellow"
Write-Log "  3) TEMIZLE-ELECTRON.bat -> Yonetici olarak tekrar dene" "Yellow"
exit 1
