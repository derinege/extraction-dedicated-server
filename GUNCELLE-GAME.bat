@echo off
title Extraction - Game guncelle (sadece game.zip)
cd /d "%~dp0"
echo.
echo  GAME GUNCELLEME (~350 MB)
echo  Panel / Playit ayarlari korunur — sadece game/ yenilenir.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\download-game.ps1"
if errorlevel 1 goto fail
echo.
echo Tamam. BASLAT-PUBLIC.bat veya BASLAT-SERVER.bat ile devam et.
goto end
:fail
echo Indirme basarisiz.
:end
pause
