@echo off
title Extraction Public Server
cd /d "%~dp0"
cd ..
set ROOT=%CD%
set LOG=%ROOT%\extraction-debug.log
echo [%date% %time%] BASLAT-PUBLIC basladi >> "%LOG%"
if not exist "public-online\host\fix-electron-public.ps1" (
  echo fix-electron-public.ps1 eksik, indiriliyor...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $dest='%~dp0host\fix-electron-public.ps1'; $u='https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/public-online/host/fix-electron-public.ps1'; Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing; $t=[IO.File]::ReadAllText($dest).TrimStart([char]0xFEFF); [IO.File]::WriteAllText($dest,$t,(New-Object Text.UTF8Encoding $false)) }"
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0host\fix-electron-public.ps1" -InstallDir "%ROOT%"
if errorlevel 1 (
  echo.
  echo Electron kurulamadi. Log: extraction-debug.log
  echo [%date% %time%] fix-electron-public BASARISIZ >> "%LOG%"
  pause
  exit /b 1
)
cd public-online\panel
echo Public panel aciliyor...
echo [%date% %time%] npm start (public) >> "%LOG%"
call npm start >> "%LOG%" 2>&1
echo [%date% %time%] npm start bitti exit=%ERRORLEVEL% >> "%LOG%"
if errorlevel 1 (
  echo.
  echo Panel acilamadi. extraction-debug.log dosyasini kontrol et.
)
pause
