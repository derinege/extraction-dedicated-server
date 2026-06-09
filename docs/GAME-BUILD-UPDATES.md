# Server build ve guncelleme

## Playit uyumlu build (Mac — sen)

Unity'de registry scriptleri guncel olmali (`EXTRACTION_PUBLIC_PORT`, `EXTRACTION_REGISTRY_SECRET`).

```bash
# 1) Windows server build
./scripts/build-windows-server.sh
# veya Unity menu: Extraction Shooter -> Build Dedicated Server (Windows)

# 2) game.zip olustur
./scripts/pack-game-zip.sh

# 3) GitHub Release (buyuk dosya — git'e commit etme)
gh release create v0.1.1-game release/game.zip \
  --repo derinege/extraction-dedicated-server \
  --title "game v0.1.1 (Playit)" \
  --notes "Registry secret + Playit public port"
```

Sonra `install-public.ps1` / `install-windows.ps1` icindeki `GameZipUrl` surumunu guncelle (ornek `v0.1.1-game`).

## Arkadas Windows'ta ne yapar?

### Ilk kurulum
`KUR-PUBLIC.bat` — game.zip otomatik iner.

### Sadece oyun guncellendi (kod/map/network degisti)
**Tam KUR gerekmez.** Sadece `game/` klasorunu degistir:

1. Sen yeni `game.zip` release at
2. Arkadas:
   - Eski `game/` sil (veya yedekle)
   - Yeni zip indir / sen at
   - `game/` icine cikart
   - Panel + Playit ayarlari **ayni kalir**
   - `BASLAT-PUBLIC.bat` -> START

Hizli indirme (PowerShell, repo kokunde):
```powershell
Invoke-WebRequest -Uri "https://github.com/derinege/extraction-dedicated-server/releases/download/v0.1.1-game/game.zip" -OutFile game.zip
Expand-Archive game.zip -DestinationPath . -Force
Remove-Item game.zip
```

### Panel / registry / Playit config guncellendi
`git pull` + gerekirse `KUR-PUBLIC.bat` (npm/electron eksikse).

## Ne zaman ne yenilenir?

| Degisiklik | Mac (sen) | Windows (arkadas) |
|------------|-----------|-------------------|
| Oyun mantigi, sahne, FishNet | Yeni server **build** + game.zip release | Sadece `game/` degistir |
| Launcher UI | Client build | Launcher kurulumu |
| Panel / Playit script | git push | `git pull` veya `KUR-PUBLIC.bat` |
| playit.config.json | — | Elle (tunnel adresleri) |
| Registry secret | — | Degisme (aynı dosya) |

## Sen (Mac oyuncu)

Build guncellemesinden **etkilenmezsin** — sadece launcher + client build. Registry URL ayni kalir.
