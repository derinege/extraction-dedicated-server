# Arkadas — dedicated server (UZAK OYUN)

Farkli evlerde oynuyorsunuz — **192.168.x.x paylasmayin**.

## 1) Node.js + KUR

1. https://nodejs.org → LTS kur → PC restart
2. Zip: https://github.com/derinege/extraction-dedicated-server/archive/refs/heads/main.zip
3. **`KUR.bat`** cift tik

## 2) Router (onemli)

Modem panelinden bu PC'ye yonlendir:

- **7777** TCP + UDP (oyun — zorunlu)
- **8787** TCP (registry — tunel kullanmazsan)

## 3) Panel

1. **`BASLAT-SERVER.bat`**
2. **IP BUL** tikla (public IP gelsin)
3. **START DEDICATED SERVER**
4. **LAUNCHER REGISTRY URL** → KOPYALA → Derin'e WhatsApp at

Ornek:
```
http://85.123.45.67:8787/v1
```

8787 acamiyorsan: **`UZAK-TUNEL.bat`** → cikan https URL + `/v1` → panele yapistir.

## 4) Firewall

Windows: 7777 ve 8787 gelen baglantiya izin ver.

---

Detay: [UZAK-OYUN.md](UZAK-OYUN.md)
