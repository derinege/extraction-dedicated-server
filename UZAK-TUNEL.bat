@echo off
title Registry Internet Tuneli (cloudflared)
cd /d "%~dp0"
echo.
echo  REGISTRY TUNELI — port 8787 forward gerekmez
echo  (Oyun portu 7777 hala router'da acilmali)
echo.
echo  Registry calisiyor olmali: BASLAT-SERVER + START once
echo.
where npx >nul 2>&1
if errorlevel 1 (
  echo HATA: Node.js / npx yok. Node LTS kur.
  pause
  exit /b 1
)
echo Tunel aciliyor... Asagida https://....trycloudflare.com cikar.
echo Panelde TUNNEL REGISTRY URL alanina yapistir: https://XXX.trycloudflare.com/v1
echo.
npx --yes cloudflared tunnel --url http://127.0.0.1:8787
pause
