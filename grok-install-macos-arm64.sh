#!/usr/bin/env bash
# Installs or updates Grok Build unified (agent-host) from x.ai and makes it plain `grok`.
# Usage: grok-install-macos-arm64.sh [--force]
set -euo pipefail

BASE="https://x.ai/cli/unified"
DL="$HOME/.grok/downloads"
BIN="$HOME/.grok/bin"
LOCAL="$HOME/.local/bin"
FORCE=0
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    -h|--help) echo "Installs or updates Grok Build unified (agent-host) from x.ai and makes it plain grok."; echo "Usage: grok-install-macos-arm64.sh [--force]"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

[ "$(uname -s)-$(uname -m)" = "Darwin-arm64" ] || { echo "this installer is for macos-aarch64 only" >&2; exit 1; }
FILE_PREFIX="agent-host"; PLAT="macos-aarch64"

V=$(curl -fsS "$BASE/latest" | tr -d '[:space:]')
[[ "$V" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "bad version from $BASE/latest: '$V'" >&2; exit 1; }
NAME="$FILE_PREFIX-$V-$PLAT"

mkdir -p "$DL" "$BIN" "$LOCAL"
CUR=$(basename "$(readlink "$BIN/agent-host" 2>/dev/null || true)")
if [ "$CUR" = "$NAME" ] && [ -x "$DL/$NAME" ] && [ "$FORCE" = 0 ]; then
  echo "already on $V"
else
  echo "downloading $V"
  SUM=$(curl -fsS "$BASE/$NAME.sha256" | cut -d' ' -f1)
  curl -fSL --progress-bar -o "$DL/$NAME.part" "$BASE/$NAME"
  echo "$SUM  $DL/$NAME.part" | shasum -a 256 -c - >/dev/null || { rm -f "$DL/$NAME.part"; echo "checksum mismatch, nothing changed" >&2; exit 1; }
  chmod 755 "$DL/$NAME.part"
  mv -f "$DL/$NAME.part" "$DL/$NAME"
  ln -sfn "../downloads/$NAME" "$BIN/agent-host"
  echo "checksum ok, linked $V"
  # keep the current and the one previous download for rollback
  ls -1t "$DL"/$FILE_PREFIX-*-$PLAT 2>/dev/null | tail -n +3 | while read -r f; do rm -f "$f"; done
fi

ln -sfn "$BIN/agent-host" "$LOCAL/grok"

case ":$PATH:" in
  *":$LOCAL:"*) ;;
  *) echo "note: $LOCAL is not on your PATH. Add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

echo "now: $("$LOCAL/grok" --version 2>&1 | head -1)"
