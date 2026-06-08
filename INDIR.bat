@echo off
title KUR.bat indir
cd /d "%~dp0"
echo KUR.bat indiriliyor...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/KUR.bat' -OutFile (Join-Path (Get-Location) 'KUR.bat') -UseBasicParsing"
if exist "KUR.bat" (
  echo.
  echo TAMAM - KUR.bat indirildi.
  echo Simdi KUR.bat dosyasina cift tikla.
) else (
  echo.
  echo HATA - indirilemedi. Internet kontrol et.
)
echo.
pause
