#!/usr/bin/env bash
# Dedicated server release klasoru hazirla (arkadasinin PC'sine kopyalanacak zip).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE="$ROOT/release/dedicated-server"
UNITY="$ROOT/asıl proje/ExtractionShooterPrototype"
PANEL="$ROOT/Tools/dedicated-server-manager"
REGISTRY="$ROOT/Tools/server-registry"

echo "=== Extraction Dedicated Server Release ==="

mkdir -p "$RELEASE/game"

copy_mac_game() {
  local src="$UNITY/Builds/Server/ExtractionShooterPrototype.app"
  local dst="$RELEASE/game/ExtractionShooterServer.app"
  if [[ ! -d "$src" ]]; then
    echo "Mac server build yok: $src"
    echo "Unity: DedicatedServerSetup.SetupAndBuildMacDedicated"
    return 1
  fi
  rm -rf "$dst"
  cp -R "$src" "$dst"
  echo "OK Mac game -> $dst"
}

copy_win_game() {
  local src="$UNITY/Builds/Server/Windows/ExtractionShooterServer.exe"
  local dst="$RELEASE/game/ExtractionShooterServer.exe"
  if [[ ! -f "$src" ]]; then
    echo "Windows server build yok: $src"
    echo "Unity (Windows module): DedicatedServerSetup.SetupAndBuildWindowsDedicated"
    return 1
  fi
  mkdir -p "$RELEASE/game/Windows"
  cp "$src" "$dst"
  # Unity Windows build Data folder
  if [[ -d "$UNITY/Builds/Server/Windows/ExtractionShooterServer_Data" ]]; then
    rm -rf "$RELEASE/game/ExtractionShooterServer_Data"
    cp -R "$UNITY/Builds/Server/Windows/ExtractionShooterServer_Data" "$RELEASE/game/"
  fi
  echo "OK Windows game -> $dst"
}

echo "[1/4] Game binary kopyala"
if [[ "${1:-}" == "win" ]]; then
  copy_win_game
elif [[ "${1:-}" == "mac" ]]; then
  copy_mac_game
else
  copy_mac_game 2>/dev/null || true
  copy_win_game 2>/dev/null || true
fi

echo "[2/4] Registry"
rm -rf "$RELEASE/registry"
mkdir -p "$RELEASE/registry"
cp "$REGISTRY/index.js" "$REGISTRY/package.json" "$RELEASE/registry/"
(cd "$REGISTRY" && npm ci --omit=dev 2>/dev/null || npm install --omit=dev)
cp -R "$REGISTRY/node_modules" "$RELEASE/registry/"

echo "[3/4] Server panel"
(cd "$PANEL" && npm install)
if [[ "${1:-}" == "win" ]]; then
  (cd "$PANEL" && npm run dist:win)
  cp "$PANEL/dist/"*win*.exe "$RELEASE/" 2>/dev/null || cp "$PANEL/dist/"*.exe "$RELEASE/" 2>/dev/null || true
elif [[ "${1:-}" == "mac" ]]; then
  # Desktop/iCloud extended attributes codesign'i kirletir.
  xattr -cr "$PANEL" 2>/dev/null || true
  xattr -cr "$RELEASE" 2>/dev/null || true
  (cd "$PANEL" && CSC_IDENTITY_AUTO_DISCOVERY=false npm run dist:mac)
  cp "$PANEL/dist/"*.dmg "$RELEASE/" 2>/dev/null || true
  # Imzasiz .app de calisir (Gatekeeper uyarisi olabilir).
  if [[ -d "$PANEL/dist/mac-arm64/Extraction Dedicated Server.app" ]]; then
    rm -rf "$RELEASE/Extraction Dedicated Server.app"
    cp -R "$PANEL/dist/mac-arm64/Extraction Dedicated Server.app" "$RELEASE/"
  fi
else
  echo "Panel paketlemek icin: ./scripts/prepare-server-release.sh mac|win"
fi

echo "[4/4] README"
cp "$PANEL/README.md" "$RELEASE/"

(
  cd "$RELEASE/.."
  zip -r "ExtractionDedicatedServer-${1:-bundle}.zip" "dedicated-server"
) 2>/dev/null || true

echo ""
echo "Hazir: $RELEASE"
echo "Zip:   $ROOT/release/ExtractionDedicatedServer-${1:-bundle}.zip"
