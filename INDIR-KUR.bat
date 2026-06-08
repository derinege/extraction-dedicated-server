@echo off
title KUR.bat indir (yedek)
cd /d "%~dp0"
echo KUR.bat indiriliyor (GitHub)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/derinege/extraction-dedicated-server/main/KUR.bat' -OutFile (Join-Path (Get-Location) 'KUR.bat') -UseBasicParsing"
if exist "KUR.bat" (
  echo TAMAM - KUR.bat indirildi. KUR.bat calistir.
) else (
  echo HATA - indirilemedi.
)
pause
