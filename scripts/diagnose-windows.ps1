# INSTALL_SCRIPT_VERSION=3
# Tam tanı raporu -> extraction-debug.log + diagnostik-rapor.txt (+ opsiyonel zip)
param(
  [string]$InstallDir = "",
  [switch]$Zip
)

$ErrorActionPreference = "Continue"
if (-not $InstallDir) {
  $InstallDir = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
}
$InstallDir = (Resolve-Path $InstallDir -ErrorAction SilentlyContinue).Path
if (-not $InstallDir) { $InstallDir = (Get-Location).Path }

$panel = Join-Path $InstallDir "Tools\dedicated-server-manager"
$registry = Join-Path $InstallDir "Tools\server-registry"
$electronPkg = Join-Path $panel "node_modules\electron"
$electronExe = Join-Path $electronPkg "dist\electron.exe"
$electronCli = Join-Path $electronPkg "cli.js"
$pathTxt = Join-Path $electronPkg "path.txt"
$gameExe = Join-Path $InstallDir "game\ExtractionShooterServer.exe"
$stateFile = Join-Path $InstallDir ".extraction-install.json"
$logFile = Join-Path $InstallDir "extraction-debug.log"
$reportFile = Join-Path $InstallDir "diagnostik-rapor.txt"

$script:Issues = New-Object System.Collections.Generic.List[string]
$script:Oks = New-Object System.Collections.Generic.List[string]

function Log($msg) {
  $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] $msg"
  Add-Content -Path $logFile -Value $line -Encoding UTF8
  Write-Host $msg
}

function Pass($msg) { $script:Oks.Add($msg); Log "  [OK] $msg" }
function Fail($msg) { $script:Issues.Add($msg); Log "  [HATA] $msg" }
function Warn($msg) { Log "  [UYARI] $msg" }

function Section($title) {
  Log ""
  Log "======== $title ========"
}

function Run-Lines($label, [scriptblock]$block) {
  Section $label
  try { & $block } catch { Fail "$label exception: $($_.Exception.Message)" }
}

function File-Info($rel) {
  $p = Join-Path $InstallDir $rel
  if (-not (Test-Path $p)) { return "EKSIK" }
  $i = Get-Item $p
  if ($i.PSIsContainer) { return "OK (klasor)" }
  return "OK ($($i.Length) byte, $($i.LastWriteTime.ToString('yyyy-MM-dd HH:mm')))"
}

function Test-Cmd($label, [scriptblock]$block) {
  Log "  > $label"
  try {
    $out = & $block 2>&1
    foreach ($line in $out) { Log "    $line" }
    return $LASTEXITCODE
  } catch {
    Log "    EXCEPTION: $($_.Exception.Message)"
    return 1
  }
}

# --- basla ---
if (Test-Path $logFile) { Remove-Item $logFile -Force }
if (Test-Path $reportFile) { Remove-Item $reportFile -Force }

Log "################################################################"
Log "#  EXTRACTION DEDICATED SERVER - TAM DIAGNOSTIK"
Log "################################################################"
Log "Kurulum klasoru: $InstallDir"
Log "Log: $logFile"
Log "Rapor: $reportFile"
Log ""

# ---- SISTEM ----
Section "SISTEM"
Log "OS: $([System.Environment]::OSVersion.VersionString)"
Log "Machine: $env:COMPUTERNAME"
Log "User: $env:USERNAME"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Log "Admin: $isAdmin"
if (-not $isAdmin) { Warn "Yonetici degilsin - bazi testler eksik kalabilir" }
Log "64bit OS: $([System.Environment]::Is64BitOperatingSystem)"
Log "Processor count: $([System.Environment]::ProcessorCount)"
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $freeGb = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
  $totalGb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
  Log "RAM: ${freeGb} GB bos / ${totalGb} GB toplam"
} catch { Warn "RAM bilgisi alinamadi" }
try {
  $disk = Get-PSDrive -Name ($InstallDir.Substring(0,1)) -ErrorAction Stop
  Log "Disk $($disk.Name): $([math]::Round($disk.Free/1GB,2)) GB bos"
  if ($disk.Free -lt 2GB) { Fail "Disk alani cok az (<2GB)" } else { Pass "Disk alani yeterli" }
} catch { Warn "Disk bilgisi alinamadi" }
if ($InstallDir -match "OneDrive") { Fail "Kurulum OneDrive icinde - sorun cikarabilir" } else { Pass "OneDrive disinda" }

# ---- NODE NPM ----
Run-Lines "NODE / NPM" {
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) { Fail "node bulunamadi" } else { Pass "node: $($node.Source)" }
  Test-Cmd "node -v" { node -v }
  Test-Cmd "npm -v" { npm -v }
  Test-Cmd "where node" { where.exe node }
  Log "  PATH (ilk 500): $($env:PATH.Substring(0, [Math]::Min(500, $env:PATH.Length)))"
  Set-Location $panel -ErrorAction SilentlyContinue
  if (Test-Path $panel) {
    Test-Cmd "npm config get prefix" { npm config get prefix }
    Test-Cmd "npm config get cache" { npm config get cache }
  }
}

# ---- DOSYALAR ----
Run-Lines "KRITIK DOSYALAR" {
  $files = @(
    "KUR.bat", "BASLAT-SERVER.bat", "FIX-ELECTRON.bat", "TEMIZLE-ELECTRON.bat", "DIAGNOSTIK.bat",
    "scripts\install-windows.ps1", "scripts\fix-electron.ps1", "scripts\diagnose-windows.ps1",
    "Tools\dedicated-server-manager\package.json",
    "Tools\dedicated-server-manager\electron\main.cjs",
    "Tools\server-registry\package.json",
    "Tools\server-registry\index.js",
    "game\ExtractionShooterServer.exe",
    "game\ExtractionShooterServer_Data\boot.config"
  )
  foreach ($f in $files) {
    $info = File-Info $f
    Log "  $info  $f"
    if ($info -eq "EKSIK") { Fail "Eksik: $f" }
  }
  if (Test-Path $gameExe) { Pass "Game binary mevcut" }

  Log "  --- game klasoru arama (tum alt agac) ---"
  $found = Get-ChildItem $InstallDir -Recurse -Filter "ExtractionShooterServer.exe" -ErrorAction SilentlyContinue
  if ($found) {
    foreach ($f in $found) {
      Log "    BULUNDU: $($f.FullName.Replace($InstallDir, '.'))"
    }
    if (-not (Test-Path $gameExe)) {
      Fail "game.exe var ama yanlis yerde - game\ klasorune tasi"
    }
  } else {
    Fail "ExtractionShooterServer.exe hicbir yerde yok - KUR.bat game indirmeli"
  }
}

# ---- INSTALL STATE ----
Run-Lines "KURULUM DURUM DOSYASI" {
  if (Test-Path $stateFile) {
    Log "  .extraction-install.json:"
    Get-Content $stateFile | ForEach-Object { Log "    $_" }
  } else {
    Warn ".extraction-install.json yok (KUR.bat hic bitmemis olabilir)"
  }
}

# ---- PANEL NODE_MODULES ----
Run-Lines "PANEL (dedicated-server-manager)" {
  if (-not (Test-Path $panel)) { Fail "Panel klasoru yok"; return }
  $nm = Join-Path $panel "node_modules"
  if (-not (Test-Path $nm)) {
    Fail "panel node_modules YOK - KUR.bat veya TEMIZLE-ELECTRON calistir"
    return
  }
  $dirs = Get-ChildItem $nm -Directory -ErrorAction SilentlyContinue
  $count = @($dirs).Count
  Log "  node_modules klasor sayisi: $count"
  if ($count -lt 10) {
    Fail "node_modules cok az ($count) - npm install yari kalmis"
  } else {
    Pass "node_modules dolu gorunuyor ($count paket)"
  }
  Log "  Ilk 25 paket: $($dirs.Name -join ', ')"

  $pkgJson = Join-Path $panel "package.json"
  if (Test-Path $pkgJson) {
    $pkg = Get-Content $pkgJson -Raw | ConvertFrom-Json
    Log "  package.json start script: $($pkg.scripts.start)"
    if ($pkg.scripts.start -notmatch "cli\.js") {
      Warn "start script eski olabilir (electron . yerine node cli.js onerilir) - yeni zip indir"
    } else {
      Pass "start script guncel (node cli.js)"
    }
  }

  Test-Cmd "npm ls electron --depth=0" { Set-Location $panel; npm ls electron --depth=0 }
}

# ---- ELECTRON DETAY ----
Run-Lines "ELECTRON DETAY" {
  if (-not (Test-Path $electronPkg)) {
    Fail "node_modules/electron yok"
    return
  }

  $checks = @{
    "index.js" = Join-Path $electronPkg "index.js"
    "cli.js" = $electronCli
    "package.json" = Join-Path $electronPkg "package.json"
    "install.js" = Join-Path $electronPkg "install.js"
    "path.txt" = $pathTxt
    "dist/electron.exe" = $electronExe
    "dist/version" = Join-Path $electronPkg "dist\version"
    ".bin/electron.cmd" = Join-Path $panel "node_modules\.bin\electron.cmd"
  }
  foreach ($k in $checks.Keys) {
    $ok = Test-Path $checks[$k]
    Log "  $k : $(if ($ok) { 'VAR' } else { 'YOK' })"
    if (-not $ok) { Fail "Electron eksik parca: $k" } else { Pass "Electron parca: $k" }
  }

  if (Test-Path $pathTxt) { Log "  path.txt = '$(Get-Content $pathTxt -Raw)'" }
  if (Test-Path (Join-Path $electronPkg "dist\version")) {
    Log "  dist/version = '$(Get-Content (Join-Path $electronPkg 'dist\version') -Raw)'"
  }
  if (Test-Path $electronExe) {
    $size = (Get-Item $electronExe).Length
    Log "  electron.exe boyut: $size byte (~$([math]::Round($size/1MB,1)) MB)"
    if ($size -lt 150MB) { Fail "electron.exe cok kucuk - bozuk indirme" }
  }

  if (Test-Path $electronExe) {
    $code = Test-Cmd "electron.exe --version" { & $electronExe --version }
    if ($code -ne 0) { Fail "electron.exe calismiyor" } else { Pass "electron.exe calisiyor" }
  }

  if (Test-Path $electronCli) {
    $code = Test-Cmd "node cli.js --version" { Set-Location $panel; node .\node_modules\electron\cli.js --version }
    if ($code -ne 0) { Fail "node cli.js calismiyor" } else { Pass "node cli.js calisiyor" }
  }

  if (Test-Path (Join-Path $electronPkg "index.js")) {
    $code = Test-Cmd "require('electron')" {
      Set-Location $panel
      node -e "try{console.log('PATH:',require('electron'))}catch(e){console.error(e.message);process.exit(1)}"
    }
    if ($code -ne 0) { Fail "require('electron') basarisiz" } else { Pass "require('electron') OK" }
  }
}

# ---- REGISTRY ----
Run-Lines "REGISTRY" {
  $regNm = Join-Path $registry "node_modules\express\package.json"
  if (Test-Path $regNm) {
    Pass "Registry npm kurulu"
    Test-Cmd "registry node_modules sayisi" {
      (Get-ChildItem (Join-Path $registry "node_modules") -Directory).Count
    }
  } else {
    Fail "Registry npm eksik - KUR.bat calistir"
  }
}

# ---- INTERNET ----
Run-Lines "INTERNET / INDIRME" {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $urls = @(
    @{ N = "npm registry"; U = "https://registry.npmjs.org/electron" },
    @{ N = "github electron zip"; U = "https://github.com/electron/electron/releases/download/v35.1.5/electron-v35.1.5-win32-x64.zip" },
    @{ N = "npmmirror"; U = "https://cdn.npmmirror.com/binaries/electron/35.1.5/electron-v35.1.5-win32-x64.zip" },
    @{ N = "game zip"; U = "https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.0-game/game.zip" },
    @{ N = "repo script"; U = "https://cdn.jsdelivr.net/gh/derinege/extraction-dedicated-server@main/scripts/fix-electron.ps1" }
  )
  foreach ($item in $urls) {
    try {
      $sw = [System.Diagnostics.Stopwatch]::StartNew()
      $r = Invoke-WebRequest -Uri $item.U -Method Head -UseBasicParsing -TimeoutSec 20
      $sw.Stop()
      Log "  OK $($r.StatusCode) (${sw}ms)  $($item.N)"
      Pass "Internet: $($item.N)"
    } catch {
      Log "  FAIL  $($item.N)  -> $($_.Exception.Message)"
      Fail "Internet: $($item.N)"
    }
  }
}

# ---- ELECTRON CACHE ----
Run-Lines "ELECTRON CACHE" {
  @(
    (Join-Path $env:LOCALAPPDATA "electron"),
    (Join-Path $env:LOCALAPPDATA "electron-builder"),
    (Join-Path $env:USERPROFILE ".cache\electron"),
    (Join-Path $env:APPDATA "npm-cache")
  ) | ForEach-Object {
    if (Test-Path $_) {
      $size = (Get-ChildItem $_ -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
      Log "  $_ -> $([math]::Round($size/1MB,1)) MB"
    } else {
      Log "  $_ -> yok"
    }
  }
}

# ---- NPM START TEST ----
Run-Lines "NPM START TEST (8 sn)" {
  if (-not (Test-Path (Join-Path $panel "package.json"))) { return }
  $job = Start-Job -ScriptBlock {
    param($p)
    Set-Location $p
    $env:ELECTRON_ENABLE_LOGGING = "1"
    npm start 2>&1
  } -ArgumentList $panel
  Start-Sleep -Seconds 8
  $out = Receive-Job $job -ErrorAction SilentlyContinue
  foreach ($line in $out) { Log "  npm> $line" }
  if ($out -match "not recognized") { Fail "npm start: electron komutu bulunamadi" }
  if ($out -match "failed to install correctly") { Fail "npm start: electron path.txt/index eksik" }
  if ($out -match "Electron failed") { Fail "npm start: electron paketi bozuk" }
  Stop-Job $job -ErrorAction SilentlyContinue
  Remove-Job $job -Force -ErrorAction SilentlyContinue
}

# ---- ESKI LOGLAR ----
Run-Lines "ONCEKI LOG DOSYALARI" {
  @("electron-install.log", "extraction-debug.log.bak") | ForEach-Object {
    $p = Join-Path $InstallDir $_
    if (Test-Path $p) {
      Log "  --- $ $_ (son 15 satir) ---"
      Get-Content $p -Tail 15 -ErrorAction SilentlyContinue | ForEach-Object { Log "    $_" }
    }
  }
}

# ---- OZET RAPOR ----
Section "OZET / VERDICT"
$report = @()
$report += "EXTRACTION DEDICATED SERVER - DIAGNOSTIK RAPOR"
$report += "Tarih: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "Klasor: $InstallDir"
$report += "User: $env:USERNAME  Admin: $isAdmin"
$report += ""
$report += "=== BASARILI ($($script:Oks.Count)) ==="
$report += $script:Oks
$report += ""
$report += "=== SORUNLAR ($($script:Issues.Count)) ==="
if ($script:Issues.Count -eq 0) {
  $report += "(yok - kurulum saglikli gorunuyor)"
} else {
  $report += $script:Issues
}
$report += ""
$report += "=== NE YAPMALI ==="
$freshInstall = (-not (Test-Path $stateFile)) -or ($script:Issues -match "panel node_modules YOK")
if ($freshInstall) {
  $report += "!!! KURULUM HIC YAPILMAMIS - ONCE KUR.bat !!!"
  $report += "1) KUR.bat calistir -> HAZIR yazana kadar bekle (~10-20 dk ilk sefer)"
  $report += "2) Electron hata verirse: TEMIZLE-ELECTRON.bat (yonetici)"
  $report += "3) BASLAT-SERVER.bat -> START DEDICATED SERVER"
} else {
  if ($script:Issues -match "node_modules|electron") {
    $report += "1) TEMIZLE-ELECTRON.bat -> Yonetici olarak calistir"
  }
  if ($script:Issues -match "game") {
    $report += "2) KUR.bat tekrar (game.zip indirir)"
  }
  if ($script:Issues -match "Registry") {
    $report += "3) KUR.bat calistir (registry npm)"
  }
}
if ($script:Issues -match "Internet") {
  $report += "- Internet / antivirus / VPN kontrol et"
}
if ($script:Issues.Count -eq 0) {
  $report += "BASLAT-SERVER.bat calistir -> START DEDICATED SERVER"
}
$report += ""
$report += "Bu dosyayi + extraction-debug.log dosyasini Derin'e gonder."

$report | Set-Content -Path $reportFile -Encoding UTF8
$report | ForEach-Object { Log $_ }

Log ""
Log "################################################################"
Log "DIAGNOSTIK BITTI"
Log "Gonder: $logFile"
Log "Gonder: $reportFile"
Log "################################################################"

if ($Zip) {
  $zipPath = Join-Path $InstallDir "diagnostik-paket.zip"
  if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
  $toZip = @($logFile, $reportFile) | Where-Object { Test-Path $_ }
  if ($toZip.Count -gt 0) {
    Compress-Archive -Path $toZip -DestinationPath $zipPath -Force
    Log "Zip olusturuldu: $zipPath"
  }
}

# Konsol ozeti renkli
Write-Host ""
Write-Host "======== OZET ========" -ForegroundColor Cyan
Write-Host "SORUN: $($script:Issues.Count)" -ForegroundColor $(if ($script:Issues.Count) { "Red" } else { "Green" })
Write-Host "OK:    $($script:Oks.Count)" -ForegroundColor Green
if ($script:Issues.Count -gt 0) {
  Write-Host ""
  Write-Host "Ilk 5 sorun:" -ForegroundColor Yellow
  $script:Issues | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
Write-Host ""
Write-Host "Rapor: $reportFile" -ForegroundColor Cyan
Write-Host "Log:   $logFile" -ForegroundColor Cyan
