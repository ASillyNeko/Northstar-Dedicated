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

echo "Writing NS_EXTRA_ARGUMENTS to $ARGS_FILE..."
echo "$NS_EXTRA_ARGUMENTS" > "$ARGS_FILE"

if [ -n "$NS_EXTRA_ARGUMENTS" ]; then
    echo "Cleaning conflicting defaults from autoexec..."
    echo "$NS_EXTRA_ARGUMENTS" | while read -r line; do
        if [ -z "$line" ]; then continue; fi

        clean_command=$(echo "$line" | sed 's/^+//')
        key=$(echo "$clean_command" | awk '{print $1}')

        sed -i "/^$key[ \t]/d" "$TARGET_CFG"
    done
fi

exec nix shell github:catornot/catornot-flakes#nswine --impure --command \
  nix run github:catornot/catornot-flakes#nswrap --impure -- \
  -dedicated \
  -port "$PORT"