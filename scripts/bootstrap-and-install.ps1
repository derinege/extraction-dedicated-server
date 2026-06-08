# KUR.bat once bunu calistirir - GitHub'dan guncel scriptleri indirir.

param(
  [string]$InstallDir = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

if (-not $InstallDir) {
  $InstallDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$BaseRaw = "https://raw.githubusercontent.com/derinege/extraction-dedicated-server/main"

$files = @(
  @{ Url = "$BaseRaw/scripts/bootstrap-and-install.ps1"; Path = "scripts\bootstrap-and-install.ps1" },
  @{ Url = "$BaseRaw/scripts/install-windows.ps1";       Path = "scripts\install-windows.ps1" },
  @{ Url = "$BaseRaw/scripts/fix-electron.ps1";          Path = "scripts\fix-electron.ps1" },
  @{ Url = "$BaseRaw/scripts/download-game.ps1";         Path = "scripts\download-game.ps1" },
  @{ Url = "$BaseRaw/scripts/setup-windows-host.ps1";    Path = "scripts\setup-windows-host.ps1" },
  @{ Url = "$BaseRaw/KUR.bat";                           Path = "KUR.bat" },
  @{ Url = "$BaseRaw/BASLAT-SERVER.bat";                 Path = "BASLAT-SERVER.bat" },
  @{ Url = "$BaseRaw/FIX-ELECTRON.bat";                  Path = "FIX-ELECTRON.bat" }
)

Write-Host "Scriptler guncelleniyor (GitHub)..." -ForegroundColor Cyan

foreach ($f in $files) {
  $dest = Join-Path $InstallDir $f.Path
  $dir = Split-Path -Parent $dest
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  try {
    Invoke-WebRequest -Uri $f.Url -OutFile $dest -UseBasicParsing
    Write-Host "  OK $($f.Path)" -ForegroundColor DarkGray
  } catch {
    Write-Host "  UYARI: $($f.Path) indirilemedi" -ForegroundColor Yellow
  }
}

Write-Host ""

$install = Join-Path $InstallDir "scripts\install-windows.ps1"
if (-not (Test-Path $install)) {
  Write-Host "HATA: install-windows.ps1 yok. Internet kontrol et." -ForegroundColor Red
  exit 1
}

& $install -InstallDir $InstallDir -Force:$Force
