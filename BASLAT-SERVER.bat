@echo off
title Extraction Dedicated Server
cd /d "%~dp0"
if not exist "scripts\fix-electron.ps1" (
  echo fix-electron.ps1 eksik, indiriliyor...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $dest='%~dp0scripts\fix-electron.ps1'; $u='https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/scripts/fix-electron.ps1'; Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing; $t=[IO.File]::ReadAllText($dest).TrimStart([char]0xFEFF); [IO.File]::WriteAllText($dest,$t,(New-Object Text.UTF8Encoding $false)) }"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix-electron.ps1"
if errorlevel 1 (
  echo.
  echo Electron kurulamadi. FIX-ELECTRON.bat ile tekrar dene.
  pause
  exit /b 1
)
cd Tools\dedicated-server-manager
echo Panel aciliyor...
call npm start
pause
