﻿# game.zip indir (Release) - repo kokune cikart
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Zip = Join-Path $Root "game.zip"
$Url = "https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.0-game/game.zip"

Write-Host "Indiriliyor: $Url"
Invoke-WebRequest -Uri $Url -OutFile $Zip -UseBasicParsing

Write-Host "Cikartiliyor: $Root"
Expand-Archive -Path $Zip -DestinationPath $Root -Force
Remove-Item $Zip -Force

if (Test-Path (Join-Path $Root "game\ExtractionShooterServer.exe")) {
  Write-Host "OK: game\ExtractionShooterServer.exe hazir" -ForegroundColor Green
} else {
  Write-Host "HATA: game klasoru olusmadi" -ForegroundColor Red
  exit 1
}
