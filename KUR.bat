@echo off
title Extraction Dedicated Server - Kurulum
cd /d "%~dp0"
echo.
echo  EXTRACTION DEDICATED SERVER - KURULUM
echo  (Eksikleri tamamlar — zaten kurulu olanlari ATLAR)
echo  Node.js LTS: https://nodejs.org
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-windows.ps1"
echo.
pause
