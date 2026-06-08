@echo off
title Extraction Dedicated Server
cd /d "%~dp0"
set LOG=%~dp0extraction-debug.log
echo [%date% %time%] BASLAT-SERVER basladi >> "%LOG%"
if not exist "scripts\fix-electron.ps1" (
  echo fix-electron.ps1 eksik, indiriliyor...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $dest='%~dp0scripts\fix-electron.ps1'; $u='https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/scripts/fix-electron.ps1'; Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing; $t=[IO.File]::ReadAllText($dest).TrimStart([char]0xFEFF); [IO.File]::WriteAllText($dest,$t,(New-Object Text.UTF8Encoding $false)) }"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\fix-electron.ps1"
if errorlevel 1 (
  echo.
  echo Electron kurulamadi.
  echo Log: extraction-debug.log
  echo DIAGNOSTIK.bat calistir, log dosyasini Derin'e at.
  echo [%date% %time%] fix-electron BASARISIZ >> "%LOG%"
  pause
  exit /b 1
)
cd Tools\dedicated-server-manager
echo Panel aciliyor...
echo [%date% %time%] npm start >> "%~dp0extraction-debug.log"
call npm start >> "%~dp0extraction-debug.log" 2>&1
echo [%date% %time%] npm start bitti exit=%ERRORLEVEL% >> "%~dp0extraction-debug.log"
if errorlevel 1 (
  echo.
  echo Panel acilamadi. extraction-debug.log dosyasini Derin'e at.
)
pause
