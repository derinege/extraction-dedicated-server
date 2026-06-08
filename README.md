# Extraction Shooter — Dedicated Server Host

Arkadaşın kasalı PC için: registry + headless dedicated panel.

**Unity kodu bu repoda yok** — sadece sunucu kurulum araçları.

## İçerik

```
Tools/server-registry/          → oyuncu listesi API (:8787)
Tools/dedicated-server-manager/ → host panel (START/STOP + monitoring)
scripts/setup-windows-host.ps1  → Windows kurulum
scripts/prepare-server-release.sh → release klasörü hazırla
docs/DEDICATED-SERVER-HOST.md
```

## Windows (arkadaş)

```powershell
git clone https://github.com/derinege/extraction-dedicated-server.git
cd REPO_NAME
powershell -ExecutionPolicy Bypass -File scripts\setup-windows-host.ps1
cd Tools\dedicated-server-manager
npm start
```

`game/` repoda yok — **Derin `game.zip` atar** (Windows headless server `.exe`, oyun client değil).

📄 [Sen ne yapacaksın](docs/SEN-NE-YAPACAKSIN.md) · [Arkadaş kurulumu](docs/ARKADAS-KURULUM.md)

## Oyuncular (siz)

Launcher → Settings → Registry URL = `http://HOST_IP:8787/v1` → FIND RAID / HOST & PLAY

Detay: [docs/DEDICATED-SERVER-HOST.md](docs/DEDICATED-SERVER-HOST.md)
