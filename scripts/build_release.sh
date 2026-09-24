#!/usr/bin/env bash
# Builds a signed DAWASA release APK and the files for the update server.
#
#   scripts/build_release.sh --notes-en "What changed" --notes-si "වෙනස් වූ දේ"
#
# Requirements (see docs/BUILD_AND_RELEASE.md):
#   * Flutter SDK and Android SDK
#   * android/key.properties pointing to your release keystore (never commit it)
#   * config/dawasa.json (copy of config/dawasa.example.json) with the verified
#     HTTPS address of your update folder, or leave it empty to build without
#     in-app updates
#
# Any extra arguments are passed to tool/generate_manifest.dart.
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${DAWASA_CONFIG:-config/dawasa.json}"

if [[ ! -f android/key.properties ]]; then
  echo "android/key.properties is missing. Create it as described in" >&2
  echo "docs/BUILD_AND_RELEASE.md; release builds are never signed with debug keys." >&2
  exit 1
fi

DEFINES=()
if [[ -f "$CONFIG" ]]; then
  DEFINES+=("--dart-define-from-file=$CONFIG")
else
  echo "Note: $CONFIG not found - building without an update server." >&2
fi

flutter --version
flutter pub get
flutter gen-l10n
flutter analyze
flutter test

flutter build apk --release \
  "${DEFINES[@]}" \
  --obfuscate --split-debug-info=build/symbols

APK=build/app/outputs/flutter-apk/app-release.apk

if command -v apksigner >/dev/null 2>&1; then
  echo "Signing certificate of the release APK:"
  apksigner verify --print-certs "$APK" | grep -i "SHA-256" || true
fi

dart run tool/generate_manifest.dart --apk "$APK" --out dist/dawasa "$@"

echo
echo "Release files are in dist/dawasa. Keep build/symbols to read crash stack traces."
