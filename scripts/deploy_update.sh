#!/usr/bin/env bash
# Uploads the files created by scripts/build_release.sh to the update folder
# on an existing web server. It only writes inside the given folder and does
# not restart, reconfigure or redeploy anything else on the server.
#
#   scripts/deploy_update.sh deploy@your-server /var/www/dawasa/downloads/dawasa
#
# The APK is uploaded and verified first; manifest.json is replaced last and
# atomically, so phones never see a manifest that points to a missing file.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <user@host> <remote-folder> [local-folder]" >&2
  exit 64
fi
HOST="$1"
DIR="$2"
SRC="${3:-dist/dawasa}"

[[ -f "$SRC/manifest.json" && -f "$SRC/SHA256SUMS" ]] || {
  echo "$SRC has no manifest.json/SHA256SUMS. Run scripts/build_release.sh first." >&2
  exit 1
}

APK_NAME="$(awk '{print $2}' "$SRC/SHA256SUMS")"
[[ -f "$SRC/$APK_NAME" ]] || { echo "Missing $SRC/$APK_NAME" >&2; exit 1; }

echo "Checking local checksum..."
(cd "$SRC" && sha256sum -c SHA256SUMS)

ssh "$HOST" "mkdir -p '$DIR'"
rsync -av --chmod=F644 "$SRC/$APK_NAME" "$SRC/SHA256SUMS" "$HOST:$DIR/"

echo "Checking the uploaded file on the server..."
ssh "$HOST" "cd '$DIR' && sha256sum -c SHA256SUMS"

if [[ -d website/public ]]; then
  rsync -av --chmod=F644 website/public/ "$HOST:$DIR/"
fi

rsync -av --chmod=F644 "$SRC/manifest.json" "$HOST:$DIR/.manifest.json.tmp"
ssh "$HOST" "mv '$DIR/.manifest.json.tmp' '$DIR/manifest.json'"

echo "Published $APK_NAME."
