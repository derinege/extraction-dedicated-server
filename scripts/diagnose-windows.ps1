# INSTALL_SCRIPT_VERSION=3
# Detayli tanı - extraction-debug.log dosyasina yazar.
param(
  [string]$InstallDir = ""
)

$ErrorActionPreference = "Continue"
if (-not $InstallDir) {
  $InstallDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$panel = Join-Path $InstallDir "Tools\dedicated-server-manager"
$electronPkg = Join-Path $panel "node_modules\electron"
$electronExe = Join-Path $electronPkg "dist\electron.exe"
$pathTxt = Join-Path $electronPkg "path.txt"
$logFile = Join-Path $InstallDir "extraction-debug.log"

function Log($msg) {
  $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
  Add-Content -Path $logFile -Value $line -Encoding UTF8
  Write-Host $msg
}

function Run-Cmd($label, $scriptBlock) {
  Log "---- $label ----"
  try {
    & $scriptBlock 2>&1 | ForEach-Object { Log "  $_" }
  } catch {
    Log "  HATA: $($_.Exception.Message)"
  }
}

if (Test-Path $logFile) { Remove-Item $logFile -Force }
Log "========================================"
Log "  EXTRACTION DEDICATED SERVER - DIAGNOSTIK"
Log "========================================"
Log "Klasor: $InstallDir"
Log "Log dosyasi: $logFile"
Log ""

Log "---- SISTEM ----"
Log "OS: $([System.Environment]::OSVersion.VersionString)"
Log "64bit OS: $([System.Environment]::Is64BitOperatingSystem)"
Log "64bit Process: $([System.Environment]::Is64BitProcess)"
Log "User: $env:USERNAME"
Log "Admin: $(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
Log "Computer: $env:COMPUTERNAME"
Log ""

Run-Cmd "NODE / NPM" {
  Log "  node path: $(Get-Command node -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)"
  node -v
  npm -v
  where.exe node
  where.exe npm
}

Run-Cmd "KLASOR KONTROL" {
  @(
    "KUR.bat",
    "BASLAT-SERVER.bat",
    "FIX-ELECTRON.bat",
    "TEMIZLE-ELECTRON.bat",
    "scripts\fix-electron.ps1",
    "Tools\dedicated-server-manager\package.json",
    "Tools\server-registry\index.js",
    "game\ExtractionShooterServer.exe"
  ) | ForEach-Object {
    $p = Join-Path $InstallDir $_
    Log "  $(if (Test-Path $p) { 'OK' } else { 'EKSIK' })  $_"
  }
}

Run-Cmd "ELECTRON DOSYALARI" {
  if (-not (Test-Path $electronPkg)) {
    Log "  node_modules/electron YOK"
    return
  }
  Log "  path.txt: $(Test-Path $pathTxt)"
  if (Test-Path $pathTxt) { Log "  path.txt icerik: $(Get-Content $pathTxt -Raw)" }
  Log "  dist/electron.exe: $(Test-Path $electronExe)"
  if (Test-Path $electronExe) { Log "  electron.exe boyut: $((Get-Item $electronExe).Length) byte" }
  Log "  dist/version: $(Test-Path (Join-Path $electronPkg 'dist\version'))"
  if (Test-Path (Join-Path $electronPkg "dist\version")) {
    Log "  version icerik: $(Get-Content (Join-Path $electronPkg 'dist\version') -Raw)"
  }
  Log "  electron klasor agaci:"
  Get-ChildItem $electronPkg -Recurse -ErrorAction SilentlyContinue | Select-Object -First 40 | ForEach-Object {
    Log "    $($_.FullName.Replace($InstallDir, '.'))"
  }
}

Run-Cmd "NODE_MODULES OZET" {
  $nm = Join-Path $panel "node_modules"
  if (Test-Path $nm) {
    $count = (Get-ChildItem $nm -Directory -ErrorAction SilentlyContinue).Count
    Log "  panel node_modules klasor sayisi: $count"
  } else {
    Log "  panel node_modules YOK"
  }
}

Run-Cmd "INTERNET TEST" {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $urls = @(
    "https://registry.npmjs.org/electron",
    "https://github.com/electron/electron/releases/download/v35.1.5/electron-v35.1.5-win32-x64.zip",
    "https://cdn.npmmirror.com/binaries/electron/35.1.5/electron-v35.1.5-win32-x64.zip"
  )
  foreach ($u in $urls) {
    try {
      $r = Invoke-WebRequest -Uri $u -Method Head -UseBasicParsing -TimeoutSec 15
      Log "  OK $($r.StatusCode)  $u"
    } catch {
      Log "  FAIL  $u  -> $($_.Exception.Message)"
    }
  }
}

Run-Cmd "ELECTRON REQUIRE TEST" {
  if (-not (Test-Path (Join-Path $panel "node_modules\electron\index.js"))) {
    Log "  electron npm paketi yok, test atlandi"
    return
  }
  Set-Location $panel
  node -e "try { const p=require('electron'); console.log('electron path:', p); } catch(e) { console.error('REQUIRE HATA:', e.message); process.exit(1); }"
  Log "  require exit: $LASTEXITCODE"
}

Run-Cmd "NPM START TEST (5 sn)" {
  if (-not (Test-Path (Join-Path $panel "package.json"))) { return }
  Set-Location $panel
  $job = Start-Job { param($p) Set-Location $p; npm start 2>&1 } -ArgumentList $panel
  Start-Sleep -Seconds 5
  Receive-Job $job -ErrorAction SilentlyContinue | ForEach-Object { Log "  $_" }
  Stop-Job $job -ErrorAction SilentlyContinue
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}

Log ""
Log "========================================"
Log "  DIAGNOSTIK BITTI"
Log "========================================"
Log "Bu dosyayi Derin'e gonder: $logFile"
Log ""
