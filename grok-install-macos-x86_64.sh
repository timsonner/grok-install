#!/usr/bin/env bash
# Installs or updates Grok Build unified (agent-host) from x.ai as `grok2`, next to your existing grok.
# Usage: grok-install-macos-x86_64.sh [--force] [--as-grok] [--keep-v1] [--revert]
set -euo pipefail

BASE="https://x.ai/cli/unified"
DL="$HOME/.grok/downloads"
BIN="$HOME/.grok/bin"
LOCAL="$HOME/.local/bin"
FORCE=0
KEEP_V1=0
REVERT=0
AS_GROK=0
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    --as-grok) AS_GROK=1 ;;
    --keep-v1) KEEP_V1=1 ;;
    --revert) REVERT=1 ;;
    -h|--help) echo "Installs or updates Grok Build unified (agent-host) from x.ai as grok2, next to your existing grok."; echo "Usage: grok-install-macos-x86_64.sh [--force] [--as-grok] [--keep-v1] [--revert]"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

[ "$(uname -s)-$(uname -m)" = "Darwin-x86_64" ] || { echo "this installer is for macos-x86_64 only" >&2; exit 1; }
FILE_PREFIX="agent-host"; PLAT="macos-x86_64"

if [ "$REVERT" = 1 ]; then
  # grok2 goes where your PATH already looks: ~/.local/bin if it is on PATH, else ~/.grok/bin
  G2DIR="$LOCAL"
  case ":$PATH:" in *":$LOCAL:"*) ;; *) G2DIR="$BIN" ;; esac
  if [ -L "$LOCAL/grok" ] && [ "$(readlink "$LOCAL/grok")" = "$BIN/agent-host" ]; then
    rm -f "$LOCAL/grok"
    ln -sfn "$BIN/agent-host" "$G2DIR/grok2"
    echo "grok2 now runs the unified build ($G2DIR/grok2, the build stays installed)"
  fi
  if [ "$G2DIR" != "$LOCAL" ] && [ -L "$LOCAL/grok2" ] && [ "$(readlink "$LOCAL/grok2")" = "$BIN/agent-host" ]; then
    rm -f "$LOCAL/grok2"
    ln -sfn "$BIN/agent-host" "$G2DIR/grok2"
    echo "moved grok2 to $G2DIR/grok2 (it is on your PATH)"
  fi
  if [ "$(readlink "$BIN/grok" 2>/dev/null || true)" = "agent-host" ]; then
    if [ -e "$BIN/grok-v1" ]; then
      mv -f "$BIN/grok-v1" "$BIN/grok"
      echo "restored old grok 1.x at $BIN/grok"
    else
      rm -f "$BIN/grok"
      echo "removed $BIN/grok (it pointed at the unified build)"
    fi
  fi
  echo "reverted. Open a new terminal, then check: type -a grok; grok --version"
  exit 0
fi

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

# grok2 goes where your PATH already looks: ~/.local/bin if it is on PATH, else ~/.grok/bin
G2DIR="$LOCAL"
case ":$PATH:" in *":$LOCAL:"*) ;; *) G2DIR="$BIN" ;; esac
if [ "$AS_GROK" = 1 ]; then
  ln -sfn "$BIN/agent-host" "$LOCAL/grok"
  if [ "$KEEP_V1" = 0 ] && [ -e "$BIN/grok" ] && [ "$(readlink "$BIN/grok" 2>/dev/null)" != "agent-host" ]; then
    mv -f "$BIN/grok" "$BIN/grok-v1"
    echo "moved old grok 1.x to $BIN/grok-v1 (use --keep-v1 to skip)"
  fi
  if [ "$KEEP_V1" = 0 ] || [ ! -e "$BIN/grok" ]; then
    ln -sfn agent-host "$BIN/grok"
  fi
  G2DIR=""
else
  ln -sfn "$BIN/agent-host" "$G2DIR/grok2"
  if [ "$G2DIR" != "$LOCAL" ] && [ -L "$LOCAL/grok2" ] && [ "$(readlink "$LOCAL/grok2")" = "$BIN/agent-host" ]; then
    rm -f "$LOCAL/grok2"
  fi
  if [ -L "$LOCAL/grok" ] && [ "$(readlink "$LOCAL/grok")" = "$BIN/agent-host" ]; then
    echo "note: $LOCAL/grok still points at the unified build from an older install. Run this script with --revert to hand grok back to your old install."
  fi
  echo "installed as grok2 ($G2DIR/grok2). Your existing grok was not touched."
fi

if [ -n "$G2DIR" ]; then
  case ":$PATH:" in
    *":$G2DIR:"*) ;;
    *) echo "note: $G2DIR is not on your PATH. Add this to your shell profile: export PATH=\"$G2DIR:\$PATH\"" ;;
  esac
else
  case ":$PATH:" in
    *":$LOCAL:"*|*":$BIN:"*) ;;
    *) echo "note: $LOCAL is not on your PATH. Add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
  esac
fi

echo "now: $("$BIN/agent-host" --version 2>&1 | head -1)"
