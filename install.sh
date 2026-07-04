#!/usr/bin/env bash
set -euo pipefail

REPO="bsomsak-dev/jlog-releases"
VERSION="${JLOG_VERSION:-latest}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

TMP_DIR="$(mktemp -d)"
cd "$TMP_DIR"

if [ "$VERSION" = "latest" ]; then
  gh release download --repo "$REPO" --pattern "jlog-node.tar.gz"
else
  gh release download "$VERSION" --repo "$REPO" --pattern "jlog-node.tar.gz"
fi

tar -xzf jlog-node.tar.gz
npm install -g .

echo "jlog installed"
jlog --version || true