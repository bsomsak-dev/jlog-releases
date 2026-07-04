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

TAG="$(
  curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
    node -e '
      let input = "";
      process.stdin.setEncoding("utf8");
      process.stdin.on("data", (chunk) => { input += chunk; });
      process.stdin.on("end", () => {
        const release = JSON.parse(input);
        if (typeof release.tag_name !== "string") process.exit(1);
        process.stdout.write(release.tag_name);
      });
    '
)"

if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Could not determine the latest stable jlog release." >&2
  exit 1
fi

PACKAGE_FILE="jlog-${TAG#v}.tgz"
CHECKSUMS_FILE="SHA256SUMS"
curl -fsSL \
  -o "$PACKAGE_FILE" \
  "https://github.com/$REPO/releases/download/$TAG/$PACKAGE_FILE"
curl -fsSL \
  -o "$CHECKSUMS_FILE" \
  "https://github.com/$REPO/releases/download/$TAG/$CHECKSUMS_FILE"
if ! grep "$PACKAGE_FILE" "$CHECKSUMS_FILE" | shasum -a 256 -c --status; then
  echo "Checksum verification failed. The downloaded package may be corrupted or tampered." >&2
  exit 1
fi

npm install -g "./$PACKAGE_FILE"

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
