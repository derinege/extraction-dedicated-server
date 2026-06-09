# Oyuncu — Public Online

Tailscale **gerekmez**. Port forward **gerekmez**.

## Launcher ayari (bir kere)

1. Launcher ac
2. **SETTINGS**
3. **NETWORK → Registry URL**
4. Host'un gonderdigi URL'yi yapistir:

```
http://85.123.45.67:8787/v1
```

Sonunda `/v1` olmali.

Mac ayar dosyasi (referans):

```
~/Library/Application Support/extraction-shooter-launcher/game-settings.json
```

`registryUrl` alani.

## Oynama

1. **FIND RAID** — host'un sunucusu listede gorunur
2. **JOIN**
3. Host harita secince raid baslar

## Hata mesajlari

| Mesaj | Ne yap |
|-------|--------|
| Registry'e ulasilamiyor | URL yanlis veya host registry kapali |
| Sunucu bulunamadi | Host START basmamis veya TTL doldu (25s) |
| Baglanti zaman asimi | Host 7777 portu acik degil |

Host ile iletisime gec — senin tarafta ek kurulum yok.
