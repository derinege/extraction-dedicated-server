# Sen ne yapacaksın (1 kere)

Arkadaş **sadece repo + game zip** ile kurar. Unity kurmaz.

## Adım 1 — Windows server build al

Mac'ten Windows `.exe` için Unity Hub:

1. **Unity 6000.4.9f1** → Add Modules → **Windows Build Support** işaretle
2. Terminal:

```bash
"/Applications/Unity/Hub/Editor/6000.4.9f1/Unity.app/Contents/MacOS/Unity" \
  -batchmode -nographics -quit \
  -projectPath "asıl proje/ExtractionShooterPrototype" \
  -executeMethod DedicatedServerSetup.SetupAndBuildWindowsDedicated
```

Çıktı:
```
asıl proje/ExtractionShooterPrototype/Builds/Server/Windows/
  ExtractionShooterServer.exe
  ExtractionShooterServer_Data/
```

**Windows PC'n varsa** aynı komutu orada çalıştır — module gerekmez.

## Adım 2 — game.zip yap, arkadaşa at

```bash
cd "asıl proje/ExtractionShooterPrototype/Builds/Server/Windows"
zip -r ~/Desktop/game.zip ExtractionShooterServer.exe ExtractionShooterServer_Data
```

Discord / Google Drive / WeTransfer → arkadaşa gönder.

## Adım 3 — Arkadaşa söyle

```
git clone https://github.com/derinege/extraction-dedicated-server.git
game.zip'i içine çıkart
scripts\setup-windows-host.ps1
cd Tools\dedicated-server-manager && npm start
```

Registry URL'ini launcher Settings'e yazarsınız.

## Opsiyonel — GitHub Release

```bash
gh release create v0.1.0 ~/Desktop/game.zip --title "Windows server binary"
```

Arkadaş Releases'tan `game.zip` indirir.
