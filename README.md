# Extraction Shooter — Dedicated Server Host

Arkadaşın kasalı PC için: registry + headless dedicated panel.

**Unity kodu bu repoda yok** — sadece sunucu kurulum araçları.

## Arkadaş (Windows) — hazır

```powershell
git clone https://github.com/derinege/extraction-dedicated-server.git
cd extraction-dedicated-server
powershell -ExecutionPolicy Bypass -File scripts\download-game.ps1
powershell -ExecutionPolicy Bypass -File scripts\setup-windows-host.ps1
cd Tools\dedicated-server-manager
npm start
```

**Server binary:** [game.zip](https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.0-game/game.zip) (335 MB, Release — git'e değil)

Panel → **START DEDICATED SERVER** (oyun penceresi yok)

📄 [Arkadaş kurulumu](docs/ARKADAS-KURULUM.md)

## Oyuncular (siz)

Launcher → Settings → Registry URL = `http://HOST_IP:8787/v1` → HOST & PLAY / FIND RAID
