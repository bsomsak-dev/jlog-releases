#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "jlog currently supports macOS only." >&2
  exit 1
fi

REPO="bsomsak-dev/jlog-releases"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"

gh release download --repo "$REPO" --pattern "*.tgz"

npm install -g ./*.tgz

JLOG_PACKAGE_DIR="$(npm root -g)/jlog"
PLAYWRIGHT_BIN="$JLOG_PACKAGE_DIR/node_modules/.bin/playwright"
JLOG_BIN="$JLOG_PACKAGE_DIR/dist/bin.js"

if [[ ! -x "$PLAYWRIGHT_BIN" ]]; then
  echo "Could not find the Playwright installer at $PLAYWRIGHT_BIN" >&2
  exit 1
fi

if [[ ! -f "$JLOG_BIN" ]]; then
  echo "Could not find the jlog executable at $JLOG_BIN" >&2
  exit 1
fi

"$PLAYWRIGHT_BIN" install chromium

echo "jlog installed"
node "$JLOG_BIN" --version

# A valid stored config can be checked without a terminal. If setup is needed,
# reconnect the wizard to the user's terminal because this script is normally
# executed with its standard input connected to curl.
if node "$JLOG_BIN" setup --if-needed >/dev/null 2>&1; then
  echo "jlog installed and configured"
  exit 0
fi

if ! exec 3<>/dev/tty; then
  echo "jlog was installed, but configuration requires an interactive terminal." >&2
  echo "Run: jlog setup" >&2
  exit 1
fi

if ! node "$JLOG_BIN" setup --if-needed <&3 >&3; then
  echo "jlog was installed, but configuration was not completed." >&2
  echo "Run: jlog setup" >&2
  exit 1
fi

echo "jlog installed and configured"
