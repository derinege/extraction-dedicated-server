# Arkadaş — teknik bilgi gerekmez

## 1) Node.js kur (1 kere)

1. Tarayıcıda aç: **https://nodejs.org**
2. **LTS** yeşil buton → indir → kur → Next Next Finish
3. PC’yi yeniden başlat (veya PowerShell kapat-aç)

> GitHub CLI **gerekmez**. Git **gerekmez**.

---

## 2) Dosyaları indir

Tarayıcıdan bu zip’i indir (GitHub hesabı gerekmez):

**https://github.com/derinege/extraction-dedicated-server/archive/refs/heads/main.zip**

Zip’i aç → klasörü masaüstüne koy, adı fark etmez.

---

## 3) Kur

Klasörün içinde **`KUR.bat`** dosyasına **çift tık**.

- İlk sefer ~335 MB server dosyası indirir (normal)
- Bitti deyince kapansın

---

## 4) Server başlat

Aynı klasörde **`BASLAT-SERVER.bat`** çift tık.

Panel açılınca → **START DEDICATED SERVER**

Derin’e panelde yazan adresi at:
```
http://SENIN_IP:8787/v1
```
(IP panelde CLIENT REGISTRY URL altında)

---

## Hata alırsan

| Mesaj | Çözüm |
|-------|--------|
| `node is not recognized` | Node.js kur, PC restart |
| `npm is not recognized` | Node.js kurulumunu tekrarla |
| `running scripts is disabled` | `KUR.bat` kullan (ExecutionPolicy bypass var) |
| İndirme hatası | VPN kapat / farklı internet dene |
| `BINARY NOT FOUND` | `KUR.bat` tekrar çalıştır |

Derin’e ekran görüntüsü at, hallederiz.
