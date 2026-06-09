# Playit.gg kurulum (Public Online)

Port forward **gerekmez**. Ev IP'si disari acilmaz.

## 1. Playit agent (host PC — Windows)

1. https://playit.gg — hesap ac
2. **Download** → Windows agent kur
3. Agent acik kalsin (system tray)

## 2. Iki tunnel olustur

Playit panelinde **Add Tunnel**:

| Tunnel | Tip | Local address | Not |
|--------|-----|---------------|-----|
| **Registry** | TCP | `127.0.0.1:8787` | Server listesi (launcher) |
| **Game** | TCP + UDP | `127.0.0.1:7777` | FishNet oyun trafigi |

Tunnel olusturunca Playit sana dis adres verir. Ornek:

- Registry: `https://abc123.share.playit.gg` veya `abc123.share.playit.gg:PORT`
- Game: `xyz789.gl.playit.gg:45123` (port **7777 olmayabilir**)

## 3. playit.config.json

Kurulum `playit.config.example.json` dosyasini kopyalar. Duzenle:

`public-online/playit.config.json`:

```json
{
  "registryPublicUrl": "https://abc123.share.playit.gg/v1",
  "gameHost": "xyz789.gl.playit.gg",
  "gamePort": 45123,
  "localGamePort": 7777,
  "localRegistryPort": 8787
}
```

- `registryPublicUrl` — launcher Settings'e yapistirilacak URL (`/v1` ile)
- `gameHost` + `gamePort` — Playit'in **game** tunnel dis adresi (JOIN icin)
- `local*` — bu PC'de panel/registry/Unity'nin dinledigi portlar

## 4. Panel

```
public-online/KUR-PUBLIC.bat    (ilk sefer)
public-online/BASLAT-PUBLIC.bat
```

1. Playit badge **yesil** / endpoint gorunur
2. **START DEDICATED SERVER**
3. **CLIENT REGISTRY URL** kopyala → oyunculara at

## 5. Oyuncu (Derin)

Launcher → **SETTINGS → Registry URL** = `registryPublicUrl` degeri

FIND RAID → JOIN. Tailscale yok.

## 6. game.zip guncellemesi

Playit modu icin server binary su env'leri kullanmali:

- `EXTRACTION_PUBLIC_ADDRESS` (gameHost)
- `EXTRACTION_PUBLIC_PORT` (Playit dis port)
- `EXTRACTION_REGISTRY_SECRET` (register/heartbeat auth)

Eski `game.zip` ile liste gelir ama kayit/heartbeat **401** olabilir veya yanlis port yazar.

**Yeni Windows server build al** (Unity'deki registry scriptleri guncel), sonra `game/` klasorune koy.

## Sorun giderme

| Sorun | Cozum |
|-------|-------|
| Playit OFFLINE | Agent acik mi? config dosyasi dolu mu? |
| Registry 401 | Yeni game build + secret dosyasi var mi? |
| Liste var, JOIN timeout | `gamePort` Playit dis port mu? UDP acik mi? |
| health acilmiyor | Registry tunnel local 8787'e bagli mi? Panel START mi? |
