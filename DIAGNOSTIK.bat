@echo off
title Extraction - Detayli Tanı
cd /d "%~dp0"
echo.
echo  Detayli log olusturuluyor...
echo  Dosya: extraction-debug.log
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose-windows.ps1"
echo.
echo  Tamam. extraction-debug.log dosyasini Derin'e at.
echo.
pause
