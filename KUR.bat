@echo off
title Extraction Dedicated Server - Kurulum
cd /d "%~dp0"
echo.
echo  EXTRACTION DEDICATED SERVER - KURULUM
echo  (Once scriptleri gunceller, sonra eksikleri kurar)
echo  Node.js LTS: https://nodejs.org
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\bootstrap-and-install.ps1"
echo.
pause
