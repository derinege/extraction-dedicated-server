# Launcher — otomatik oyun guncellemesi

Oyuncu launcher acinca internet varsa **en guncel client** indirilir. Sen sadece release atarsin.

## Akis

```
Sen (Mac)                          Oyuncu launcher
─────────                          ───────────────
Unity client build
pack-client-mac.sh
gh release (client-mac.zip)
client-manifest.json version bump
git push
                                   Acilis → manifest cek
                                   Yeni surum → zip indir
                                   ~/Library/.../game/ kur
                                   JOIN / PLAY
```

## Senin isin (her oyun guncellemesi)

```bash
# 1) Unity client build (Mac)
./scripts/build-windows-server.sh   # veya Unity menu — client icin ayri build eklenebilir

# 2) Mac client zip
./scripts/pack-client-mac.sh 0.1.2

# 3) GitHub Release
gh release create v0.1.2-client-mac release/client-mac.zip \
  --repo derinege/extraction-dedicated-server \
  --title "client mac v0.1.2"

# 4) client-manifest.json
# version: "0.1.2"
# platforms.darwin.url → yeni release URL

git add client-manifest.json && git commit && git push
```

**5 dakika sonra** tum acik launcher'lar guncel surumu ceker.

## Oyuncu

- Kurulum bir kere (launcher)
- Internet acik → otomatik guncelleme
- Registry URL ayari degismez
- `game/` klasoru: `~/Library/Application Support/extraction-shooter-launcher/game/`

## Dev mod (sen)

`npm run app` → `EXTRACTION_LAUNCHER_DEV=1` → auto-update **kapali**, repo'daki local build kullanilir.

Production test:
```bash
npm run open
```

## Manifest

`client-manifest.json` (repo kokunde):

| Alan | Aciklama |
|------|----------|
| `version` | Surum (0.1.2) |
| `platforms.darwin.url` | Mac zip |
| `platforms.win32.url` | Windows zip |
| `platforms.*.binary` | Zip icindeki exe/app yolu |

Manifest URL override: `CLIENT_MANIFEST_URL` env
