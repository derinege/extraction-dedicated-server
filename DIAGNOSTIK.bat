@echo off
title Extraction - TAM Diagnostik
cd /d "%~dp0"
echo.
echo  ========================================
echo   EXTRACTION - TAM DIAGNOSTIK
echo  ========================================
echo.
echo  Bu arac:
echo   - Tum dosyalari kontrol eder
echo   - Electron / npm / game / registry test eder
echo   - Internet indirmesini dener
echo   - npm start simulasyonu yapar
echo   - OZET rapor + cozum onerisi yazar
echo.
echo  Cikti dosyalari:
echo   extraction-debug.log   (detayli)
echo   diagnostik-rapor.txt   (ozet - bunu oku)
echo   diagnostik-paket.zip   (ikisini zip - Derin'e at)
echo.
pause
echo Calisiyor, 30-60 sn surebilir...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\diagnose-windows.ps1" -Zip
echo.
if exist "diagnostik-rapor.txt" (
  echo ===== OZET RAPOR =====
  type "diagnostik-rapor.txt"
  echo.
)
echo ========================================
echo  Derin'e gonder: diagnostik-paket.zip
echo  veya: diagnostik-rapor.txt + extraction-debug.log
echo ========================================
echo.
pause
