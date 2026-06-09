@echo off
title Extraction Public Server - Kurulum
cd /d "%~dp0"
cd ..
set ROOT=%CD%
echo.
echo  EXTRACTION PUBLIC SERVER - KURULUM
echo  Tailscale YOK - port forward gerekir (7777, 8787)
echo  Klasor: %ROOT%
echo  Node.js LTS: https://nodejs.org
echo.
if not exist "public-online\host" mkdir "public-online\host"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ErrorActionPreference = 'Stop'; $root = '%ROOT%'; $scriptDir = Join-Path $root 'public-online\host'; $dest = Join-Path $scriptDir 'install-public.ps1'; $ver = 'INSTALL_SCRIPT_VERSION=PUBLIC-2'; $urls = @( 'https://raw.githubusercontent.com/derinege/extraction-dedicated-server/main/public-online/host/install-public.ps1', ('https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/public-online/host/install-public.ps1?v=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) ); New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ok = $false; foreach ($u in $urls) { try { Write-Host ('Indiriliyor: ' + $u); Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing; $t = [IO.File]::ReadAllText($dest).TrimStart([char]0xFEFF); [IO.File]::WriteAllText($dest, $t, (New-Object Text.UTF8Encoding $false)); if ($t -match [regex]::Escape($ver)) { Write-Host 'Script guncel (PUBLIC-2)' -ForegroundColor Green; $ok = $true; break }; Write-Host 'Gecersiz cevap, diger URL...' -ForegroundColor Yellow } catch { Write-Host ('Hata: ' + $_.Exception.Message) -ForegroundColor Yellow } }; if (-not $ok) { if (Test-Path $dest) { Write-Host 'Yerel script kullaniliyor...' -ForegroundColor Yellow; $ok = $true } else { Write-Host 'HATA: install-public.ps1 yok.' -ForegroundColor Red; exit 1 } }; & $dest -InstallDir $root }"
if errorlevel 1 goto fail
echo.
echo Public kurulum bitti.
goto end
:fail
echo.
echo Kurulum basarisiz. Yonetici olarak dene veya extraction-debug.log kontrol et.
:end
echo.
pause
