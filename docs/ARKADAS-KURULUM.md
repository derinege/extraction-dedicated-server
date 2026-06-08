# Arkadaşın kasası — 5 dakika kurulum

**Oyun açılmaz.** Sadece panel + headless server.

## 1) Node.js kur

https://nodejs.org → LTS indir, kur.

## 2) Repo + server dosyası

```powershell
git clone https://github.com/derinege/extraction-dedicated-server.git
cd extraction-dedicated-server
```

**Derin'den `game.zip` al** (Discord/Drive) → repo klasörüne çıkart:

```
extraction-dedicated-server/
  game/
    ExtractionShooterServer.exe
    ExtractionShooterServer_Data/
```

> `game/` yoksa panel açılır ama START çalışmaz.

## 3) Kur + başlat

```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup-windows-host.ps1
cd Tools\dedicated-server-manager
npm start
```

Panel → **START DEDICATED SERVER**

Sana vereceği URL: `http://SENIN_LAN_IP:8787/v1`  
(Bu IP panelde CLIENT REGISTRY URL altında yazar.)

## Firewall

- **8787** TCP (registry)
- **7777** UDP (oyun)
