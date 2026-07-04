#!/usr/bin/env bash
set -euo pipefail

REPO="bsomsak-dev/jlog-releases"
TMP_DIR="$(mktemp -d)"

cd "$TMP_DIR"

gh release download --repo "$REPO" --pattern "*.tgz"

npm install -g ./*.tgz

echo "jlog installed"
jlog --version || true