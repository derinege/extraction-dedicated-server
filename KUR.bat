@echo off
title Extraction Dedicated Server - Kurulum
cd /d "%~dp0"
echo.
echo  EXTRACTION DEDICATED SERVER - KURULUM
echo  (Git gerekmez. Node.js LTS kurulu olmali: https://nodejs.org)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-windows.ps1"
echo.
pause
