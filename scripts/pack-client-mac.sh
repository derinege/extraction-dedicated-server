#!/usr/bin/env bash
# Mac client zip — launcher auto-update icin GitHub Release
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UNITY="$ROOT/asıl proje/ExtractionShooterPrototype"
VERSION="${1:-0.1.1}"

SRC="$UNITY/Builds/Client/ExtractionShooterPrototype.app"
if [[ ! -d "$SRC" ]]; then
  SRC="$UNITY/Builds/Server/ExtractionShooterPrototype.app"
fi
if [[ ! -d "$SRC" ]]; then
  echo "Client build yok. Unity: Build Dedicated Server (Mac) veya Client build ekle."
  exit 1
fi

OUT="$ROOT/release/client-mac.zip"
mkdir -p "$ROOT/release"
rm -f "$OUT"
(
  cd "$(dirname "$SRC")"
  zip -r "$OUT" "$(basename "$SRC")"
)

echo "OK: $OUT"
echo ""
echo "1) gh release create v${VERSION}-client-mac \"$OUT\" --repo derinege/extraction-dedicated-server"
echo "2) client-manifest.json version + url guncelle"
echo "3) git push main (manifest)"
