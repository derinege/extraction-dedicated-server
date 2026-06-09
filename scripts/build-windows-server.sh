#!/usr/bin/env bash
# Mac'ten Windows dedicated server build (Unity Windows module gerekir)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/asıl proje/ExtractionShooterPrototype"
LOG="$ROOT/BuildLogs/windows-server-build.log"

mkdir -p "$ROOT/BuildLogs"

UNITY=""
for ver in 6000.4.9f1 6000.3.11f1; do
  p="/Applications/Unity/Hub/Editor/$ver/Unity.app/Contents/MacOS/Unity"
  if [[ -x "$p" ]]; then UNITY="$p"; break; fi
done

if [[ -z "$UNITY" ]]; then
  echo "HATA: Unity bulunamadi. Hub'dan Editor kur."
  exit 1
fi

echo "Unity: $UNITY"
echo "Proje: $PROJECT"
echo "Log: $LOG"

"$UNITY" \
  -batchmode -quit -nographics \
  -projectPath "$PROJECT" \
  -executeMethod DedicatedServerSetup.SetupAndBuildWindowsDedicated \
  -logFile "$LOG"

echo "Build bitti. Log son satirlar:"
tail -20 "$LOG"
