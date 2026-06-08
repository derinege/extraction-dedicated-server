# Arkadasin Windows PC — dedicated server klasoru (zip yerine kopyala-yapistir veya git pull)
# Kullanim: PowerShell -ExecutionPolicy Bypass -File setup-windows-host.ps1
param(
  [string]$RepoUrl = "",
  [string]$TargetDir = "$env:USERPROFILE\ExtractionDedicatedServer"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Extraction Dedicated Server (Windows) ===" -ForegroundColor Cyan

if ($RepoUrl) {
  if (Test-Path $TargetDir) {
    Write-Host "Guncelleniyor: $TargetDir"
    Set-Location $TargetDir
    git pull
  } else {
    git clone $RepoUrl $TargetDir
    Set-Location $TargetDir
  }
} elseif (-not (Test-Path $TargetDir)) {
  New-Item -ItemType Directory -Path $TargetDir | Out-Null
  Write-Host "Klasor olusturuldu: $TargetDir"
  Write-Host "Repo zip veya git clone ile dosyalari buraya kopyala."
}

$panel = Join-Path $TargetDir "Tools\dedicated-server-manager"
$registry = Join-Path $TargetDir "Tools\server-registry"

if (-not (Test-Path $panel)) {
  Write-Host "HATA: Tools\dedicated-server-manager bulunamadi. Once repo dosyalarini kopyala." -ForegroundColor Red
  exit 1
}

Write-Host "[1/3] Registry npm install"
Set-Location $registry
npm install --omit=dev

Write-Host "[2/3] Panel npm install"
Set-Location $panel
npm install

Write-Host "[3/3] Game binary kontrol"
$gameExe = Join-Path $TargetDir "game\ExtractionShooterServer.exe"
$unityBuild = Join-Path $TargetDir "asıl proje\ExtractionShooterPrototype\Builds\Server\Windows\ExtractionShooterServer.exe"
if (-not (Test-Path $gameExe)) {
  if (Test-Path $unityBuild) {
    New-Item -ItemType Directory -Path (Split-Path $gameExe) -Force | Out-Null
    Copy-Item $unityBuild $gameExe
    $dataSrc = Join-Path $TargetDir "asıl proje\ExtractionShooterPrototype\Builds\Server\Windows\ExtractionShooterServer_Data"
    if (Test-Path $dataSrc) {
      Copy-Item $dataSrc (Join-Path $TargetDir "game\ExtractionShooterServer_Data") -Recurse -Force
    }
    Write-Host "Unity build -> game\ kopyalandi"
  } else {
    Write-Host "UYARI: game\ExtractionShooterServer.exe yok. Unity Windows dedicated build gerekli." -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "Baslatmak icin:" -ForegroundColor Green
Write-Host "  cd `"$panel`""
Write-Host "  npm start"
Write-Host ""
Write-Host "Veya portable exe: npm run dist:win  (cikti: dist\ExtractionDedicatedServer-0.1.0-win.exe)"
