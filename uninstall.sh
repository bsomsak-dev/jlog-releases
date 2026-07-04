#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--purge]

Uninstall the global jlog npm package.

Options:
  --purge  Also remove jlog configuration and runtime data after confirmation
  --help   Show this help
EOF
}

PURGE=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --purge)
      PURGE=true
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [ "$(uname -s)" != "Darwin" ]; then
  echo "jlog currently supports macOS only." >&2
  exit 1
fi

CONFIG_DIR="$HOME/.config/jlog"
DATA_DIR="$HOME/.local/share/jlog"

if [ "$PURGE" = true ]; then
  echo "This will uninstall jlog and permanently remove:"
  echo "  $CONFIG_DIR"
  echo "  $DATA_DIR"
  echo "Playwright's shared browser cache will not be removed."

  if ! exec 3<>/dev/tty; then
    echo "Cannot confirm purge without an interactive terminal." >&2
    exit 1
  fi

  printf "Type yes to continue: " >&3
  IFS= read -r ANSWER <&3
  if [ "$ANSWER" != "yes" ]; then
    echo "Cancelled; jlog and its data were not removed."
    exit 0
  fi
fi

npm uninstall -g jlog
echo "jlog uninstalled"

if [ "$PURGE" = true ]; then
  rm -rf "$CONFIG_DIR" "$DATA_DIR"
  echo "jlog configuration and runtime data removed"
else
  echo "Configuration and runtime data were kept:"
  echo "  $CONFIG_DIR"
  echo "  $DATA_DIR"
  echo "Run the uninstaller with --purge to remove them."
fi
