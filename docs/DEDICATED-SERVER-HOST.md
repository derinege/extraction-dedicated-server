# Dedicated Server — Arkadaşın PC’si

## Roller

| Kim | Ne yapar |
|-----|----------|
| **Arkadaş (kasalı PC)** | Dedicated Server Panel → START |
| **Siz (2 PC)** | Launcher → HOST & PLAY (biri) + FIND RAID → JOIN (digeri) |

## Arkadaş kurulumu (Windows — zip şart değil)

1. **Git clone** veya klasör kopyala (Drive/USB)
2. `powershell -File scripts\setup-windows-host.ps1`
3. `cd Tools\dedicated-server-manager && npm start`
4. **START DEDICATED SERVER** — harita seçmez, sadece sunucu + monitoring
5. Size **CLIENT REGISTRY URL** verin (`http://IP:8787/v1`)

Harita / raid adı → oyuncunun launcher **HOST & PLAY** ekranında.

Detay: [Tools/dedicated-server-manager/README.md](../Tools/dedicated-server-manager/README.md)

## Oyuncu kurulumu

1. `cd Extractionshootermainmenuui && npm run app`
2. **SETTINGS → NETWORK → SERVER REGISTRY URL** = arkadaşın URL
3. **MULTIPLAYER → FIND RAID → JOIN**

## Port forward (internet)

- `8787` TCP — registry
- `7777` UDP/TCP — FishNet
