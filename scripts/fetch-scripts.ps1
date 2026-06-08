# INSTALL_SCRIPT_VERSION=3
# Helper - downloads fresh scripts from GitHub/jsDelivr.
param(
  [string]$InstallDir = ""
)

$ErrorActionPreference = "Stop"

if (-not $InstallDir) {
  $InstallDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$scriptDir = Join-Path $InstallDir "scripts"
$versionMarker = "INSTALL_SCRIPT_VERSION=3"
$baseRaw = "https://raw.githubusercontent.com/derinege/extraction-dedicated-server/main"
$baseCdn = "https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main"

$files = @(
  "install-windows.ps1",
  "fix-electron.ps1",
  "fetch-scripts.ps1"
)

New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Utf8NoBom($path, $text) {
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($path, $text, $utf8)
}

function Normalize-Ps1File($path) {
  $text = [System.IO.File]::ReadAllText($path).TrimStart([char]0xFEFF)
  Write-Utf8NoBom $path $text
  return $text
}

function Download-ScriptFile($name) {
  $dest = Join-Path $scriptDir $name
  $urls = @(
    "$baseCdn/scripts/$name",
    "$baseRaw/scripts/$name"
  )

  foreach ($url in $urls) {
    try {
      Write-Host "  Indiriliyor: $url" -ForegroundColor DarkGray
      Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
      $text = Normalize-Ps1File $dest
      if ($text -match [regex]::Escape($versionMarker)) {
        Write-Host "  OK $name" -ForegroundColor Green
        return $true
      }
      Write-Host "  Gecersiz cevap: $name" -ForegroundColor Yellow
    } catch {
      Write-Host "  Hata ($name): $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }

  return $false
}

Write-Host "Scriptler indiriliyor..." -ForegroundColor Cyan

$allOk = $true
foreach ($file in $files) {
  if (-not (Download-ScriptFile $file)) {
    $allOk = $false
    Write-Host "HATA: $file indirilemedi" -ForegroundColor Red
  }
}

if (-not $allOk) {
  exit 1
}

Write-Host "Tum scriptler guncel (v3)" -ForegroundColor Green
