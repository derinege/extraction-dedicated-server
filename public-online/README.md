# Public Online (Playit.gg)

Tailscale akisindan **ayri**. `KUR.bat` / `Tools/dedicated-server-manager` degismez.

| Mod | Host | Oyuncu |
|-----|------|--------|
| **Tailscale** (test/ev) | Kok `KUR.bat` | Tailscale + launcher |
| **Playit** (gercek online) | `public-online/KUR-PUBLIC.bat` | Sadece launcher |

## Hizli baslangic (Windows host)

1. Node.js LTS
2. https://playit.gg agent kur
3. `public-online/KUR-PUBLIC.bat`
4. `public-online/playit.config.json` doldur ([rehber](docs/PLAYIT-SETUP.md))
5. `public-online/BASLAT-PUBLIC.bat` → START → URL oyunculara

## Oyuncu

Settings → Registry URL = host'un `registryPublicUrl` degeri → FIND RAID → JOIN

## Guvenlik

Registry localhost + secret token + rate limit. Detay: [docs/SECURITY.md](docs/SECURITY.md)

## Dosyalar

```
public-online/
  playit.config.example.json   Ornek (commit)
  playit.config.json           Gercek ayar (gitignore)
  secrets/registry-secret.txt  Otomatik uretilir (gitignore)
  KUR-PUBLIC.bat
  BASLAT-PUBLIC.bat
  panel/                       Ayni Electron UI
  docs/PLAYIT-SETUP.md
```

Paylasilan: `game/`, `Tools/server-registry/`

## Onemli: game build

Playit + registry secret icin **guncel** `ExtractionShooterServer.exe` gerekir (`EXTRACTION_PUBLIC_PORT`, `EXTRACTION_REGISTRY_SECRET`). Eski release zip yetmeyebilir — Unity'den yeni server build al.
