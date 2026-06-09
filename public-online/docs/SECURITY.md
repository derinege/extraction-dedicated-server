# Guvenlik — Public Online (Playit)

## Ne yapiyoruz

| Onlem | Aciklama |
|-------|----------|
| **Registry localhost bind** | Registry sadece `127.0.0.1` dinler; dis erisim sadece Playit tunnel |
| **Registry secret** | `register` / `heartbeat` / `unregister` icin `X-Registry-Token` zorunlu |
| **Rate limit** | IP basina istek siniri (okuma + yazma) |
| **Private IP engeli** | Registry'ye `192.168.x` gibi adresler yazilamaz |
| **Max server** | Liste basina max 8 kayit (env ile) |
| **Playit** | Ev router'da port acilmaz, ev IP gizli |

Secret dosyasi: `public-online/secrets/registry-secret.txt` (git'e girmez, kurulumda uretilir).

## Oyuncu tarafi

- Launcher sadece **GET /servers** yapar (okuma) — token gerekmez
- Registry URL'yi sadece guvendigin kisilerle paylas (liste herkese acik)

## Tailscale modu

`KUR.bat` / `Tools/dedicated-server-manager` ayri kalir. Registry secret **zorunlu degil** (env bos ise eski davranis).

## Ileride (opsiyonel)

- Registry read token (launcher'da ayar)
- Join sifresi / lobby PIN
- Steam / EOS auth
