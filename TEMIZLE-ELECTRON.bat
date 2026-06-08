@echo off
title Electron sil ve yeniden kur
cd /d "%~dp0"
echo.
echo  Electron SILINIYOR ve bastan kuruluyor (~150 MB)
echo  Antivirus uyarsa IZIN VER.
echo  Log: extraction-debug.log
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix-electron.ps1" -Force
echo.
pause
