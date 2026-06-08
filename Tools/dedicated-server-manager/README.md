# Extraction Dedicated Server Panel

Arkadaşının kasalı PC’sinde çalışacak **dedicated server arayüzü**.

- Registry (server listesi) başlatır
- Headless Unity dedicated server başlatır/durdurur
- Client’ların bağlanacağı IP ve registry URL’ini gösterir

## Hızlı başlangıç (geliştirici — paket oluştur)

### 1. Unity server build

**Windows (arkadaşın PC’si):**
```bash
Unity -batchmode -quit -projectPath "asıl proje/ExtractionShooterPrototype" \
  -executeMethod DedicatedServerSetup.SetupAndBuildWindowsDedicated
```

**Mac (test):**
```bash
Unity -batchmode -quit -projectPath "asıl proje/ExtractionShooterPrototype" \
  -executeMethod DedicatedServerSetup.SetupAndBuildMacDedicated
```

### 2. Arkadaşa gönderme (zip şart değil)

**A) Git (en temiz)** — arkadaş Windows’ta:
```powershell
git clone <repo-url> %USERPROFILE%\ExtractionDedicatedServer
cd %USERPROFILE%\ExtractionDedicatedServer
powershell -ExecutionPolicy Bypass -File scripts\setup-windows-host.ps1
cd Tools\dedicated-server-manager
npm start
```

**B) Klasör kopyala** — USB / Google Drive / Discord:
- `Tools/dedicated-server-manager/`
- `Tools/server-registry/`
- `game/ExtractionShooterServer.exe` + `_Data` (Windows Unity build)
- `scripts/setup-windows-host.ps1`

Zip yerine **klasörü olduğu gibi** at; arkadaş `npm start` ile paneli açar.

**C) Tek portable exe** (panel only, `game/` yanında durmalı):
```bash
cd Tools/dedicated-server-manager && npm run dist:win
# dist/ExtractionDedicatedServer-0.1.0-win.exe + game/ klasörünü aynı dizine koy
```

**D) GitHub Releases** — `prepare-server-release.sh win` ile zip, Releases’a yükle.

### 3. Arkadaş ne yapar

Panel → **START DEDICATED SERVER** (harita seçmez — sadece sunucu)

Oyuncular haritayı launcher **HOST & PLAY** ekranında seçer.

Panelde: bağlı oyuncular, ping, server health.

**CLIENT REGISTRY URL**’i size verin (ör. `http://192.168.1.50:8787/v1`).

---

## Sizin PC’ler (oyuncu / launcher)

1. `Extractionshootermainmenuui` → `npm run app`
2. **SETTINGS → NETWORK → SERVER REGISTRY URL** → arkadaşın URL’si
3. **MULTIPLAYER → FIND RAID → REFRESH → JOIN**

---

## Portlar

| Port | Ne |
|------|-----|
| **8787** | Registry (HTTP — server listesi) |
| **7777** | FishNet oyun (UDP/TCP) |

Router’da ikisini de forward edin (internet üzerinden oynayacaksanız).

---

## Geliştirme modu (panel only)

```bash
cd Tools/dedicated-server-manager
npm install
npm start
```

`game/` klasörü yoksa repo’daki Unity build yolunu otomatik dener.

---

## GitHub

Repo’ya push sonrası arkadaş:

```bash
git clone <repo-url>
cd ExtractionShootercodes
./scripts/prepare-server-release.sh win
```

veya **Releases** sekmesinden hazır zip indirir.

---

## Sorun giderme

| Sorun | Çözüm |
|-------|--------|
| BINARY NOT FOUND | `prepare-server-release.sh win` çalıştır |
| FIND RAID boş | Registry URL doğru mu, firewall 8787 açık mı |
| JOIN olmuyor | Aynı map, port 7777 açık, registry’de server görünüyor mu |
| Sadece LAN | PUBLIC IP alanına LAN IP yazın; WAN için router forward |
