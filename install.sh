#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "jlog currently supports macOS only." >&2
  exit 1
fi

REPO="bsomsak-dev/jlog-releases"
TMP_DIR="$(mktemp -d)"

cd "$TMP_DIR"

gh release download --repo "$REPO" --pattern "*.tgz"

npm install -g ./*.tgz

JLOG_PACKAGE_DIR="$(npm root -g)/jlog"
PLAYWRIGHT_BIN="$JLOG_PACKAGE_DIR/node_modules/.bin/playwright"

if [[ ! -x "$PLAYWRIGHT_BIN" ]]; then
  echo "Could not find the Playwright installer at $PLAYWRIGHT_BIN" >&2
  exit 1
fi

"$PLAYWRIGHT_BIN" install chromium

echo "jlog installed"
jlog --version
echo "Run: jlog setup"
