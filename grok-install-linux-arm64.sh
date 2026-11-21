#!/usr/bin/env bash
# Installs or updates Grok Build unified (agent-host) from x.ai and makes it plain `grok`.
# Usage: grok-install-linux-arm64.sh [--force] [--keep-v1] [--revert]
set -euo pipefail

BASE="https://x.ai/cli/unified"
DL="$HOME/.grok/downloads"
BIN="$HOME/.grok/bin"
LOCAL="$HOME/.local/bin"
FORCE=0; KEEP_V1=0; REVERT=0
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    --keep-v1) KEEP_V1=1 ;;
    --revert) REVERT=1 ;;
    -h|--help) echo "Installs or updates Grok Build unified (agent-host) from x.ai and makes it plain grok."; echo "Usage: grok-install-linux-arm64.sh [--force] [--keep-v1] [--revert]"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

[ "$(uname -s)-$(uname -m)" = "Linux-aarch64" ] || { echo "this installer is for linux-aarch64 only" >&2; exit 1; }
FILE_PREFIX="agent-host"; PLAT="linux-aarch64"

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
  MISE_CFG="$HOME/.config/mise/config.toml"
  if [ -f "$MISE_CFG" ] && grep -q '^disable_tools.*"grok"' "$MISE_CFG"; then
    cp -n "$MISE_CFG" "$MISE_CFG.bak-grok2"
    sed -i -e '/^disable_tools/{s/, *"grok"//;s/"grok" *, *//;s/"grok"//}' "$MISE_CFG"
    echo "re-enabled mise grok (backup: config.toml.bak-grok2)"
    if command -v mise >/dev/null 2>&1; then
      mise install grok@latest || echo "mise install grok failed, run it by hand: mise install grok@latest" >&2
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
  echo "$SUM  $DL/$NAME.part" | sha256sum -c - >/dev/null || { rm -f "$DL/$NAME.part"; echo "checksum mismatch, nothing changed" >&2; exit 1; }
  chmod 755 "$DL/$NAME.part"
  mv -f "$DL/$NAME.part" "$DL/$NAME"
  ln -sfn "../downloads/$NAME" "$BIN/agent-host"
  echo "checksum ok, linked $V"
  # keep the current and the one previous download for rollback
  ls -1t "$DL"/$FILE_PREFIX-*-$PLAT 2>/dev/null | tail -n +3 | xargs -r rm -f
fi

ln -sfn "$BIN/agent-host" "$LOCAL/grok"
if [ "$KEEP_V1" = 0 ] && [ -e "$BIN/grok" ] && [ "$(readlink "$BIN/grok" 2>/dev/null)" != "agent-host" ]; then
  mv -f "$BIN/grok" "$BIN/grok-v1"
  echo "moved old grok 1.x to $BIN/grok-v1 (use --keep-v1 to skip)"
fi
if [ "$KEEP_V1" = 0 ] || [ ! -e "$BIN/grok" ]; then
  ln -sfn agent-host "$BIN/grok"
fi
[ -e "$LOCAL/grok2" ] && rm -f "$LOCAL/grok2" && echo "removed grok2"

if command -v mise >/dev/null 2>&1; then
  if ! mise settings get disable_tools 2>/dev/null | grep -qw grok; then
    cp -n "$HOME/.config/mise/config.toml" "$HOME/.config/mise/config.toml.bak.pre-grok2" 2>/dev/null || true
    mise settings add disable_tools grok
    echo "disabled mise grok (backup: config.toml.bak.pre-grok2)"
  fi
  MISE_GROK="${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/grok"
  if [ "$KEEP_V1" = 0 ] && [ -n "$(ls -A "$MISE_GROK" 2>/dev/null)" ]; then
    mise uninstall --all grok >/dev/null 2>&1 || true
    rm -rf "$MISE_GROK"
    echo "removed mise grok 1.x"
  fi
fi

case ":$PATH:" in
  *":$LOCAL:"*|*":$BIN:"*) ;;
  *) echo "note: $LOCAL is not on your PATH. Add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

echo "now: $("$LOCAL/grok" --version 2>&1 | head -1)"
