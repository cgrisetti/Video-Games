#!/usr/bin/env bash
# Optional: installs the Terrain3D addon for local development (Mode A terrain,
# 10_WORLD_ARCHITECTURE.md §4.4). Everwood runs without it: with no
# addons/terrain_3d the world draws its own ground meshes (Mode B). addons/ is
# gitignored, so each machine fetches its own copy. Run from games/everwood:
#   tools/fetch_terrain3d.sh
set -euo pipefail
VERSION="v1.1.0-stable"
URL="https://github.com/TokisanGames/Terrain3D/releases/download/${VERSION}/Terrain3D_${VERSION}.zip"
cd "$(dirname "$0")/.."
if [ -e addons/terrain_3d ]; then echo "addons/terrain_3d is already here (delete it first to reinstall)."; exit 0; fi
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
curl -fL --progress-bar -o "$work/terrain3d.zip" "$URL"
unzip -q "$work/terrain3d.zip" -d "$work/unpacked"
found="$(find "$work/unpacked" -type d -path "*addons/terrain_3d" | head -1)"
[ -n "$found" ] || { echo "No addons/terrain_3d in the download."; exit 1; }
mkdir -p addons && mv "$found" addons/terrain_3d
echo "Terrain3D ${VERSION} installed (only the addon, not its demo). Now run: godot --headless --path . --import"
