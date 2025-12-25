#!/bin/sh
set -e

if [ -d "$WINEPREFIX" ]; then
    chown -R root:root "$WINEPREFIX"
fi

cd "$TF2_DIR"
PORT=${NS_PORT:-37015}

TARGET_CFG="R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg"
DEFAULT_CFG="/etc/northstar/autoexec_ns_server.cfg"

mkdir -p "$(dirname "$TARGET_CFG")"

if [ -f "$DEFAULT_CFG" ]; then
    cp "$DEFAULT_CFG" "$TARGET_CFG"
fi

exec nix shell github:catornot/catornot-flakes#nswine --impure --command \
  nix run github:catornot/catornot-flakes#nswrap --impure -- \
  -dedicated \
  -port "$PORT" \
  $NS_EXTRA_ARGUMENTS