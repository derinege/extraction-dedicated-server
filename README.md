# Extraction Shooter — Dedicated Server Host

Arkadaşın kasalı PC: panel + headless server (oyun client değil).

## Arkadaş (Windows) — Git yok, GitHub CLI yok

1. **Node.js LTS** → https://nodejs.org (kur, restart)
2. Zip indir → https://github.com/derinege/extraction-dedicated-server/archive/refs/heads/main.zip
3. Aç → **`KUR.bat`** çift tık
4. **`BASLAT-SERVER.bat`** çift tık → START DEDICATED SERVER

📄 Detay: [docs/ARKADAS-KURULUM.md](docs/ARKADAS-KURULUM.md)

## Oyuncular (Derin) — farkli ev / internet

Launcher → **SETTINGS → NETWORK → SERVER REGISTRY URL**  
Arkadasin panelden kopyaladigi **public** URL (192.168 degil):

```
http://85.xxx.xxx.xxx:8787/v1
```

veya cloudflare tuneli: `https://xxx.trycloudflare.com/v1`

📄 Detay: [docs/UZAK-OYUN.md](docs/UZAK-OYUN.md)
