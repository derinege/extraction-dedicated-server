# Extraction Shooter — Dedicated Server (Windows)

Arkadasin PC: headless dedicated server + panel.  
Oyuncular: launcher ile **FIND RAID → JOIN**.

**Uzaktan oyun = Tailscale.** Port forward yok, `192.168.x.x` kullanma.

---

## Tailscale nedir?

Ikiniz farkli evde/internette oynuyorsunuz. Tailscale sizi sanal bir LAN gibi birlestirir (`100.x.x.x` IP).

| Kim | Tailscale |
|-----|-----------|
| Arkadas (Windows server) | `KUR.bat` ile kurulur |
| Derin (Mac oyuncu) | https://tailscale.com/download/mac |

**Sart:** Ayni tailnet — birbirinizi davet edin.

---

## Arkadas — Windows (server PC)

### 1) Kurulum (1 kere)

1. **Node.js LTS** → https://nodejs.org → kur → PC restart
2. Repo zip veya `git pull` → klasore gir
3. **`KUR.bat`** cift tik  
   - Server binary, panel, **Tailscale** kurulur

### 2) Tailscale giris (1 kere)

- KUR sonrasi Tailscale acilir (veya Baslat menusunden **Tailscale**)
- **Google / Microsoft** ile giris yap
- Derin'i davet et: https://login.tailscale.com/admin/settings/users → **Invite user**  
  (veya Derin seni davet etsin — fark etmez, ayni tailnet yeterli)

### 3) Server baslat (her oyun gecesi)

1. **`BASLAT-SERVER.bat`**
2. Panelde **Tailscale** satiri **100.x.x.x ONLINE** olmali
3. **START DEDICATED SERVER**
4. **CLIENT REGISTRY URL** → **KOPYALA**
5. Derin'e WhatsApp/Discord ile at

Ornek URL:
```
http://100.64.55.123:8787/v1
```

(`100.` ile baslar — `192.168` **degil**)

### 4) Durdur

Panel → **STOP**

---

## Derin — Mac (oyuncu)

1. **Tailscale** kur + giris (arkadasla **ayni tailnet**)
2. Launcher ac → **SETTINGS → NETWORK → SERVER REGISTRY URL**
3. Arkadasin gonderdigi URL'yi yapistir
4. **MULTIPLAYER → FIND RAID → REFRESH → JOIN**

---

## Tailscale sorun giderme

| Sorun | Cozum |
|-------|--------|
| Panelde Tailscale OFFLINE | Tailscale uygulamasini ac, giris yap |
| URL `192.168.x.x` | Yanlis — Tailscale baglaninca `100.x.x.x` olmali |
| Derin server goremiyor | Ayni tailnet mi? Davet kabul edildi mi? |
| REGISTRY ERROR | URL sonu `/v1` olmali, arkadas START yapti mi? |
| JOIN olmuyor | Server START + Heartbeat OK mi? Tailscale ONLINE mi? |

---

## Dosyalar

| Dosya | Is |
|-------|-----|
| `KUR.bat` | Ilk kurulum (Node, game, panel, Tailscale) |
| `BASLAT-SERVER.bat` | Panel ac |
| `FIX-ELECTRON.bat` | Electron bozuksa |
| `TEMIZLE-ELECTRON.bat` | Panel npm temiz kurulum |

Detayli Windows hata cozumu: `docs/ARKADAS-KURULUM.md`
