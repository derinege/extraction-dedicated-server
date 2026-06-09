# Host kurulum — Public Online

## Gereksinimler

- Windows 10/11
- Node.js LTS
- Statik veya degismeyen public IP (CGNAT varsa Playit.gg dusun)
- Modeme erisim (port forward)

## Adim adim

### 1. Kurulum

```
public-online/KUR-PUBLIC.bat
```

Indirir/kurar:
- `game/ExtractionShooterServer.exe`
- `Tools/server-registry` (npm)
- `public-online/panel` (Electron)

Tailscale **kurulmaz**.

### 2. Port forward (modem)

| Port | Protokol | Amac |
|------|----------|------|
| 7777 | TCP + UDP | FishNet oyun trafigi |
| 8787 | TCP | Registry (FIND RAID listesi) |

Host PC'nin **yerel IP**sine yonlendir (ornek `192.168.1.50`).

### 3. Windows Firewall

Kurulum scripti kural eklemeyi dener. Manuel:

```powershell
netsh advfirewall firewall add rule name="Extraction Game 7777 TCP" dir=in action=allow protocol=TCP localport=7777
netsh advfirewall firewall add rule name="Extraction Game 7777 UDP" dir=in action=allow protocol=UDP localport=7777
netsh advfirewall firewall add rule name="Extraction Registry 8787" dir=in action=allow protocol=TCP localport=8787
```

### 4. Panel

```
public-online/BASLAT-PUBLIC.bat
```

- **PUBLIC IP DETECT** — internetten IP alir
- **START DEDICATED SERVER**
- **CLIENT REGISTRY URL** kopyala → Discord/WhatsApp

Oyuncular bu URL'yi launcher Settings'e yazar.

### 5. Dogrulama

Baska agdan (mobil veri) tarayicida ac:

```
http://SENIN_PUBLIC_IP:8787/v1/health
```

`{"ok":true}` donmeli.

## CGNAT / port forward yok

Ev internetinde public IP yoksa veya modem kapaliysa:

1. **Playit.gg** — ucretsiz tunnel, 7777 ve 8787 icin agent
2. **VPS** — ucuz cloud sunucuda ayni panel + binary

Registry tunnel kullaniyorsan panelde **Tunnel Registry URL** alanina yaz (ornek `https://xxx.trycloudflare.com/v1`). Oyun portu icin ayrica cozum gerekir.

## Sorun giderme

| Sorun | Cozum |
|-------|-------|
| Public IP yanlis | Panelde manuel **Public IP** yaz, kaydet |
| Registry health acilmiyor | 8787 forward + firewall |
| JOIN oluyor ama baglanmiyor | 7777 UDP forward eksik olabilir |
| Liste bos | Server START mi? Heartbeat 25s TTL |
