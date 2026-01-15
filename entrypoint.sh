#!/bin/sh
set -e

TMP_BASE="/tmp/northstar"
mkdir -p "$TMP_BASE"
find "$TMP_BASE" -maxdepth 1 -type d -name 'nstmp*' -exec rm -rf {} + 2>/dev/null || true
export TMPDIR="$TMP_BASE/nstmp$$$(shuf -i 1000-9999 -n 1)"
mkdir -p "$TMPDIR"

if [ ! -d "$TF2_DIR/" ]; then
	echo "TF2 directory $TF2_DIR does not exist or is not a directory."
	exit 1
fi

if [ ! -d "$NORTHSTAR_DIR/" ]; then
	echo "Northstar directory $NORTHSTAR_DIR does not exist or is not a directory."
	exit 1
fi

ln -sf "$TF2_DIR"/* "$TMPDIR/"
ln -sf "$NORTHSTAR_DIR"/* "$TMPDIR/"

cd "$TMPDIR"
PORT=${NS_PORT:-37015}

TARGET_CFG="$TMPDIR/R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg"
BACKUP_CFG="$TARGET_CFG.bak"

if [ -f "$BACKUP_CFG" ]; then
	cp "$BACKUP_CFG" "$TARGET_CFG"
else
	cp "$TARGET_CFG" "$BACKUP_CFG"
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