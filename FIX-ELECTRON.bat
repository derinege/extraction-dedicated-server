@echo off
title Electron duzeltme
cd /d "%~dp0"
echo.
echo  Electron yeniden indiriliyor (~150 MB)...
echo  Antivirus uyarsa IZIN VER.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix-electron.ps1"
echo.
pause
