@echo off
title Electron sil ve yeniden kur
cd /d "%~dp0"
echo.
echo  Electron SILINIYOR ve bastan kuruluyor (~150 MB)
echo  Antivirus uyarsa IZIN VER.
echo  Log: extraction-debug.log
echo.
if not exist "scripts" mkdir "scripts"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { $ErrorActionPreference = 'Stop'; $root = '%CD%'; $scriptDir = Join-Path $root 'scripts'; $dest = Join-Path $scriptDir 'fix-electron.ps1'; $ver = 'INSTALL_SCRIPT_VERSION=4'; $urls = @( 'https://raw.githubusercontent.com/derinege/extraction-dedicated-server/main/scripts/fix-electron.ps1', ('https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/scripts/fix-electron.ps1?v=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) ); New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ok = $false; foreach ($u in $urls) { try { Write-Host ('Indiriliyor: ' + $u); Invoke-WebRequest -Uri $u -OutFile $dest -UseBasicParsing; $t = [IO.File]::ReadAllText($dest).TrimStart([char]0xFEFF); [IO.File]::WriteAllText($dest, $t, (New-Object Text.UTF8Encoding $false)); if ($t -match [regex]::Escape($ver) -and $t -notmatch 'Run-NpmLogged\(\$args\)') { Write-Host 'Script guncel (v4)' -ForegroundColor Green; $ok = $true; break } } catch { Write-Host ('Hata: ' + $_.Exception.Message) -ForegroundColor Yellow } }; if (-not $ok) { Write-Host 'HATA: fix-electron.ps1 indirilemedi veya bozuk.' -ForegroundColor Red; exit 1 }; & $dest -InstallDir $root -Force }"
echo.
pause
