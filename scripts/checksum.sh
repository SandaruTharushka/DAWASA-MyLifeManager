#!/usr/bin/env bash
# Prints the SHA-256 checksum of a file (for example a downloaded APK), so it
# can be compared with the value on the download page.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <file>" >&2
  exit 64
fi
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$1"
else
  shasum -a 256 "$1"
fi
