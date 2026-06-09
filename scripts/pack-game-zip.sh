#!/usr/bin/env bash
# Windows dedicated server -> game.zip (GitHub Release icin)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UNITY="$ROOT/asıl proje/ExtractionShooterPrototype"
SRC="$UNITY/Builds/Server/Windows"
OUT="$ROOT/release/game.zip"
STAGE="$ROOT/release/game-staging"

if [[ ! -f "$SRC/ExtractionShooterServer.exe" ]]; then
  echo "HATA: Build yok: $SRC/ExtractionShooterServer.exe"
  echo "Unity: Extraction Shooter -> Build Dedicated Server (Windows)"
  echo "Veya: ./scripts/build-windows-server.sh"
  exit 1
fi

echo "=== pack game.zip (Playit-ready server) ==="
rm -rf "$STAGE"
mkdir -p "$STAGE/game"

# Tum Windows build ciktisi gerekli (dll, MonoBleedingEdge, _Data)
rsync -a --exclude='*_BurstDebugInformation_DoNotShip' "$SRC/" "$STAGE/game/"

# Burst debug klasoru ship edilmemeli
rm -rf "$STAGE/game/"*_BurstDebugInformation_DoNotShip 2>/dev/null || true

mkdir -p "$ROOT/release"
rm -f "$OUT"
(
  cd "$STAGE"
  zip -r "$OUT" game -x "*.DS_Store"
)

rm -rf "$STAGE"
BYTES=$(stat -f%z "$OUT" 2>/dev/null || stat -c%s "$OUT")
echo "OK: $OUT ($BYTES bytes)"
echo "Yukle: gh release create v0.1.1-game \"$OUT\" --repo derinege/extraction-dedicated-server --title \"game v0.1.1 (Playit)\" --notes \"Playit: EXTRACTION_PUBLIC_PORT + registry secret\""
