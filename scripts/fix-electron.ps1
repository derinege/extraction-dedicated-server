# INSTALL_SCRIPT_VERSION=3
# Electron binary eksik/bozuk ise yeniden indirir.
param(
  [string]$InstallDir = ""
)

$ErrorActionPreference = "Stop"
if (-not $InstallDir) {
  $InstallDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$panel = Join-Path $InstallDir "Tools\dedicated-server-manager"
$electronExe = Join-Path $panel "node_modules\electron\dist\electron.exe"

if (Test-Path $electronExe) {
  Write-Host "Electron OK: $electronExe" -ForegroundColor Green
  exit 0
}

Write-Host ""
Write-Host "Electron eksik, yeniden indiriliyor (~150 MB)..." -ForegroundColor Yellow
Write-Host "Antivirus uyarsa izin ver." -ForegroundColor Yellow
Write-Host ""

Set-Location $panel

if (Test-Path "node_modules\electron") {
  Remove-Item -Recurse -Force "node_modules\electron"
}

npm install electron@35.1.5 --save-dev --foreground-scripts --no-audit --no-fund

if (-not (Test-Path $electronExe)) {
  Write-Host ""
  Write-Host "HATA: Electron hala kurulamadi." -ForegroundColor Red
  Write-Host "  1) PowerShell Yonetici olarak ac" -ForegroundColor Yellow
  Write-Host "  2) Antivirus gecici kapat" -ForegroundColor Yellow
  Write-Host "  3) FIX-ELECTRON.bat tekrar calistir" -ForegroundColor Yellow
  exit 1
}

Write-Host ""
Write-Host "Electron kuruldu. BASLAT-SERVER.bat calistir." -ForegroundColor Green
