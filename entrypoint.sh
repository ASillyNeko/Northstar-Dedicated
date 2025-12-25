#!/bin/sh
set -e

if [ -d "$WINEPREFIX" ]; then
    chown -R root:root "$WINEPREFIX"
fi

cd "$TF2_DIR"
PORT=${NS_PORT:-37015}

TARGET_CFG="R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg"
DEFAULT_CFG="/etc/northstar/autoexec_ns_server.cfg"
ARGS_FILE="ns_startup_args.txt"


mkdir -p "$(dirname "$TARGET_CFG")"
if [ -f "$DEFAULT_CFG" ]; then
    cp "$DEFAULT_CFG" "$TARGET_CFG"
fi

if [ -n "$NS_EXTRA_ARGUMENTS" ]; then
    printf '%s\n' "$NS_EXTRA_ARGUMENTS" | sed 's/^[[:space:]]*//' | grep -E '^[+-]' | while read -r arg; do
        key=$(printf '%s' "$arg" | sed 's/^[+-]//' | awk '{print $1}')
        [ -n "$key" ] && sed -i "/^$key[ \t]/d" "$TARGET_CFG"
    done
fi

set -- nix shell github:catornot/catornot-flakes#nswine --impure --command \
    nix run github:catornot/catornot-flakes#nswrap --impure -- \
    -dedicated \
    -port "$PORT"
    NS_EXTRA_ONELINE=""
    if [ -n "$NS_EXTRA_ARGUMENTS" ]; then
        NS_EXTRA_ONELINE=$(printf '%s' "$NS_EXTRA_ARGUMENTS" | tr '\n' ' ')
    fi

    CMD="nix shell github:catornot/catornot-flakes#nswine --impure --command nix run github:catornot/catornot-flakes#nswrap --impure -- -dedicated -port \"$PORT\" $NS_EXTRA_ONELINE"
    exec sh -c "$CMD"