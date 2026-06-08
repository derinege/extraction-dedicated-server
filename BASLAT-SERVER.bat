@echo off
title Extraction Dedicated Server
cd /d "%~dp0"
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
