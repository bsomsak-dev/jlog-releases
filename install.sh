#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "workctl currently supports macOS only." >&2
  exit 1
fi

REPO="bsomsak-dev/workctl-releases"
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
  echo "Could not determine the latest stable workctl release." >&2
  exit 1
fi

PACKAGE_FILE="workctl-${TAG#v}.tgz"
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

WORKCTL_PACKAGE_DIR="$(npm root -g)/workctl"
PLAYWRIGHT_BIN="$WORKCTL_PACKAGE_DIR/node_modules/.bin/playwright"
WORKCTL_BIN="$WORKCTL_PACKAGE_DIR/dist/packages/cli/src/bin.js"

if [[ ! -x "$PLAYWRIGHT_BIN" ]]; then
  echo "Could not find the Playwright installer at $PLAYWRIGHT_BIN" >&2
  exit 1
fi

if [[ ! -f "$WORKCTL_BIN" ]]; then
  echo "Could not find the workctl executable at $WORKCTL_BIN" >&2
  exit 1
fi

"$PLAYWRIGHT_BIN" install chromium

echo "workctl installed"
node "$WORKCTL_BIN" --version

# The install script normally receives stdin from curl, so reconnect the
# onboarding hub to the user's terminal. Installation remains successful when
# onboarding is unavailable, cancelled, or incomplete.
if ! exec 3<>/dev/tty; then
  echo "workctl installed. Onboarding requires an interactive terminal." >&2
  echo "Run: workctl setup" >&2
  exit 0
fi

if ! node "$WORKCTL_BIN" setup <&3 >&3 2>&3; then
  echo "workctl installed, but onboarding was not completed." >&2
  echo "Run: workctl setup" >&2
  exit 0
fi

echo "workctl installation complete"
