@echo off
title Extraction Dedicated Server - Kurulum
cd /d "%~dp0"
echo.
echo  EXTRACTION DEDICATED SERVER - KURULUM
echo  Klasor: %CD%
echo  Script internetten indirilir - sadece bu dosyaya cift tikla.
echo  Node.js LTS: https://nodejs.org
echo.
if not exist "scripts" mkdir "scripts"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ErrorActionPreference = 'Stop'; $root = '%CD%'; $scriptDir = Join-Path $root 'scripts'; $dest = Join-Path $scriptDir 'install-windows.ps1'; $ver = 'INSTALL_SCRIPT_VERSION=4'; $urls = @( 'https://raw.githubusercontent.com/derinege/extraction-dedicated-server/main/scripts/install-windows.ps1', ('https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/scripts/install-windows.ps1?v=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) ); New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ok = $false; foreach ($u in $urls) { try { Write-Host ('Indiriliyor: ' + $u); Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing; $t = [IO.File]::ReadAllText($dest).TrimStart([char]0xFEFF); [IO.File]::WriteAllText($dest, $t, (New-Object Text.UTF8Encoding $false)); if ($t -match [regex]::Escape($ver)) { Write-Host 'Script guncel (v4)' -ForegroundColor Green; $ok = $true; break }; Write-Host 'Gecersiz cevap, diger URL deneniyor...' -ForegroundColor Yellow } catch { Write-Host ('Hata: ' + $_.Exception.Message) -ForegroundColor Yellow } }; if (-not $ok) { Write-Host 'HATA: install-windows.ps1 indirilemedi veya bozuk.' -ForegroundColor Red; if (Test-Path $dest) { Write-Host 'Indirilen dosyanin ilk satirlari:'; Get-Content $dest -TotalCount 5 }; exit 1 }; & $dest -InstallDir $root }"
if errorlevel 1 goto fail
echo.
echo Kurulum bitti.
goto end
:fail
echo.
echo Kurulum basarisiz.
echo Log: extraction-debug.log
echo Electron icin: TEMIZLE-ELECTRON.bat (yonetici)
echo Tani icin: DIAGNOSTIK.bat
:end
echo.
pause
