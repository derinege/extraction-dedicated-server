# Tek script — Git / GitHub CLI gerekmez. Tarayicidan zip de olur.
# Kullanim: sag tik KUR.bat -> Calistir  VEYA  powershell -ExecutionPolicy Bypass -File scripts\install-windows.ps1

param(
  [string]$InstallDir = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $InstallDir) { $InstallDir = $RepoRoot }

$RepoZipUrl = "https://github.com/derinege/extraction-dedicated-server/archive/refs/heads/main.zip"
$GameZipUrl = "https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.0-game/game.zip"

function Write-Step($msg) {
  Write-Host ""
  Write-Host ">> $msg" -ForegroundColor Cyan
}

function Ensure-Node {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) {
    Write-Host ""
    Write-Host "HATA: Node.js yok." -ForegroundColor Red
    Write-Host "1) https://nodejs.org ac" -ForegroundColor Yellow
    Write-Host "2) LTS indir, kur (Next Next)" -ForegroundColor Yellow
    Write-Host "3) PC yeniden baslat veya PowerShell kapat-ac" -ForegroundColor Yellow
    Write-Host "4) KUR.bat tekrar calistir" -ForegroundColor Yellow
    exit 1
  }
  Write-Host "Node: $(node -v)  npm: $(npm -v)" -ForegroundColor DarkGray
}

function Download-File($Url, $Dest) {
  Write-Host "Indiriliyor..." -ForegroundColor DarkGray
  Write-Host $Url
  try {
    Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
  } catch {
    Write-Host "Indirme basarisiz. VPN / internet / tarayici ile dene." -ForegroundColor Red
    throw
  }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EXTRACTION DEDICATED SERVER KURULUM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Klasor: $InstallDir"

Ensure-Node

$panel = Join-Path $InstallDir "Tools\dedicated-server-manager"
$registry = Join-Path $InstallDir "Tools\server-registry"

# Repo dosyalari yoksa GitHub'dan indir (git gerekmez)
if (-not (Test-Path $panel)) {
  Write-Step "Panel dosyalari indiriliyor (GitHub zip)"
  $tmp = Join-Path $env:TEMP "extraction-server-setup"
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null
  $repoZip = Join-Path $tmp "repo.zip"
  Download-File $RepoZipUrl $repoZip
  Expand-Archive -Path $repoZip -DestinationPath $tmp -Force
  $extracted = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "extraction-dedicated-server*" } | Select-Object -First 1
  if (-not $extracted) { throw "Repo zip acilamadi" }
  if ($InstallDir -ne $extracted.FullName) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -Path "$($extracted.FullName)\*" -Destination $InstallDir -Recurse -Force
  }
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

$panel = Join-Path $InstallDir "Tools\dedicated-server-manager"
$registry = Join-Path $InstallDir "Tools\server-registry"
if (-not (Test-Path $panel)) { throw "Tools\dedicated-server-manager bulunamadi: $InstallDir" }

# game.zip
$gameExe = Join-Path $InstallDir "game\ExtractionShooterServer.exe"
if (-not (Test-Path $gameExe)) {
  Write-Step "Server dosyasi indiriliyor (game.zip ~335 MB, biraz surer)"
  $gameZip = Join-Path $InstallDir "game.zip"
  Download-File $GameZipUrl $gameZip
  Expand-Archive -Path $gameZip -DestinationPath $InstallDir -Force
  Remove-Item $gameZip -Force -ErrorAction SilentlyContinue
  if (-not (Test-Path $gameExe)) { throw "game\ExtractionShooterServer.exe olusmadi" }
  Write-Host "OK: server binary hazir" -ForegroundColor Green
} else {
  Write-Host "Server binary zaten var." -ForegroundColor DarkGray
}

Write-Step "Registry kuruluyor (npm install)"
Set-Location $registry
npm install --omit=dev

Write-Step "Panel kuruluyor (npm install)"
Set-Location $panel
npm install

# Baslat batch
$startBat = Join-Path $InstallDir "BASLAT-SERVER.bat"
@"
@echo off
title Extraction Dedicated Server
cd /d "%~dp0Tools\dedicated-server-manager"
echo Panel aciliyor...
call npm start
pause
"@ | Set-Content -Path $startBat -Encoding ASCII

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  KURULUM TAMAM" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Simdi calistir:" -ForegroundColor Yellow
Write-Host "  $startBat" -ForegroundColor White
Write-Host ""
Write-Host "Panel acilinca: START DEDICATED SERVER" -ForegroundColor Yellow
Write-Host "Derin'e CLIENT REGISTRY URL ver (ornek http://SENIN_IP:8787/v1)" -ForegroundColor Yellow
Write-Host ""

Set-Location $InstallDir
