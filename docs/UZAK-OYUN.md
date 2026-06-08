# Uzak oyun — farkli evler, farkli internet

192.168.x.x **sadece ayni evde** calisir. Farkli sehirlerdeyseniz asagidaki adimlar sart.

---

## Ozet

| Ne | Nerede |
|----|--------|
| Dedicated server | Arkadasin guclu PC (Windows) |
| Registry listesi | `8787` portu veya cloudflare tuneli |
| Oyun baglantisi | `7777` portu (router forward **sart**) |
| Sen (Derin) | Launcher Settings → **public registry URL** |

---

## Yol A — Port forward (klasik)

**Arkadas router'da** (modem arayuzu):

1. Bu PC'nin **yerel IP**'sine yonlendir (ornek `192.168.1.13`)
2. **7777** → TCP + UDP (oyun)
3. **8787** → TCP (registry — tunel kullanmiyorsan)

**Arkadas panelde:**

1. `BASLAT-SERVER.bat` → **IP BUL** → public IP gelsin
2. **START DEDICATED SERVER**
3. **LAUNCHER REGISTRY URL** satirini kopyala → Derin'e at  
   Ornek: `http://85.123.45.67:8787/v1`

**Derin launcher:**

SETTINGS → NETWORK → SERVER REGISTRY URL = arkadasin gonderdigi URL (192.168 **degil**)

---

## Yol B — Registry tuneli + oyun portu

8787 acamiyorsan:

1. `BASLAT-SERVER.bat` → START
2. **`UZAK-TUNEL.bat`** calistir
3. Cikan `https://xxxx.trycloudflare.com` → panele yapıştir:  
   `https://xxxx.trycloudflare.com/v1`
4. **7777** port forward yine sart (oyun trafigi)

---

## Yol C — Tailscale (en kolay, router ugrasmadan)

1. Ikiniz de **https://tailscale.com** kur
2. Arkadas Tailscale IP'si (100.x.x.x) → panel **PUBLIC IP** alanina yaz
3. Registry URL: `http://100.x.x.x:8787/v1`
4. Port forward **gerekmez**

---

## Windows Firewall (arkadas)

Gelen kurallar:

- TCP **8787**
- TCP + UDP **7777**

---

## Test (Derin Mac terminal)

```bash
curl "http://ARKADAS_PUBLIC_IP:8787/v1/servers"
```

veya tunel:

```bash
curl "https://xxxx.trycloudflare.com/v1/servers"
```

`servers` dolu geliyorsa launcher'da REFRESH.

---

## Sik hatalar

| Belirti | Sebep |
|---------|--------|
| REGISTRY ERROR | Yanlis URL veya 8787 kapali |
| Liste bos | Server START degil veya heartbeat yok |
| Goruyor ama JOIN olmuyor | 7777 forward yok veya public IP yanlis |
| 192.168.x.x kullandin | Uzaktan calismaz |
