# Arkadaşın kasası — hazır kurulum

**Oyun açılmaz.** Panel + headless server.

## Tek komut zinciri (PowerShell)

```powershell
git clone https://github.com/derinege/extraction-dedicated-server.git
cd extraction-dedicated-server
powershell -ExecutionPolicy Bypass -File scripts\download-game.ps1
powershell -ExecutionPolicy Bypass -File scripts\setup-windows-host.ps1
cd Tools\dedicated-server-manager
npm start
```

Panel → **START DEDICATED SERVER** → sana registry URL verir.

## Gereksinimler

- [Node.js LTS](https://nodejs.org)
- Git
- Firewall: **8787** TCP, **7777** UDP

## game.zip

Release'ten otomatik iner: [game.zip](https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.0-game/game.zip)

Manuel: indir → repo köküne çıkart → `game/` klasörü oluşsun.
