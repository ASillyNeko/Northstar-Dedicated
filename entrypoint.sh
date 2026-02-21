#!/bin/sh
set -e

TF2_DIR=/titanfall2
NORTHSTAR_DIR=/northstar
MODS_DIR=/mnt/mods
PLUGINS_DIR=/mnt/plugins
TMP_DIR=/tmp/northstar

if [ -d "$TMP_DIR/" ]; then
	rm -r $TMP_DIR
fi

mkdir $TMP_DIR

if [ ! -d "$TF2_DIR/" ]; then
	echo "TF2 directory doesn't exist or is not a directory."
	exit 1
fi

if [ -n "$(find "$TF2_DIR" -maxdepth 0 -empty)" ]; then
	echo "TF2 directory is empty"
	exit 1
fi

if [ ! -d "$NORTHSTAR_DIR/" ]; then
	echo "Northstar directory doesn't exist or is not a directory."
	exit 1
fi

if [ -n "$(find "$NORTHSTAR_DIR" -maxdepth 0 -empty)" ]; then
	echo "Northstar directory is empty"
	exit 1
fi

find "$TF2_DIR" -type d | while read -r tf2_dir; do
	rel_path="${tf2_dir#$TF2_DIR}"
	rel_path="${rel_path#/}"
	[ -n "$rel_path" ] && mkdir -p "$TMP_DIR/$rel_path"
done

find "$NORTHSTAR_DIR" -type d | while read -r ns_dir; do
	rel_path="${ns_dir#$NORTHSTAR_DIR}"
	rel_path="${rel_path#/}"
	[ -n "$rel_path" ] && mkdir -p "$TMP_DIR/$rel_path"
done

find "$TF2_DIR" -type f -o -type l | while read -r tf2_file; do
	rel_path="${tf2_file#$TF2_DIR}"
	rel_path="${rel_path#/}"
	[ -n "$rel_path" ] && ln -sf "$tf2_file" "$TMP_DIR/$rel_path"
done

find "$NORTHSTAR_DIR" -type f -o -type l | while read -r ns_file; do
	rel_path="${ns_file#$NORTHSTAR_DIR}"
	rel_path="${rel_path#/}"
	[ -n "$rel_path" ] && ln -sf "$ns_file" "$TMP_DIR/$rel_path"
done

if [ -d "$MODS_DIR" ]; then
	for mod in "$MODS_DIR"/*/; do
		[ -d "$mod" ] || continue

		mod_name=$(basename "$mod")
		target="$TMP_DIR/R2Northstar/mods/$mod_name"

		if [ -e "$target" ] || [ -L "$target" ]; then
			echo "Error: cannot overwrite built-in mod/file, '$mod_name'"
			echo "Change your volume to '/northstar/R2Northstar/mods:ro' if you want to overwrite built-in mods/files"
			exit 1
		fi

		ln -sf "$mod" "$target"
	done
fi

if [ -d "$PLUGINS_DIR" ]; then
	for plugin in "$PLUGINS_DIR"/*; do
		[ -f "$plugin" ] || continue

		plugin_name=$(basename "$plugin")
		target="$TMP_DIR/R2Northstar/plugins/$plugin_name"

		if [ -e "$target" ] || [ -L "$target" ]; then
			echo "Error: cannot overwrite built-in plugin/file, '$plugin_name'"
			echo "Change your volume to '/northstar/R2Northstar/plugins:ro' if you want to overwrite built-in plugins/files"
			exit 1
		fi

		ln -sf "$plugin" "$target"
	done
fi

cd "$TMP_DIR"

PORT=${NS_PORT:-37016}
TARGET_CFG="$TMP_DIR/R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg"

if [ -n "$NS_EXTRA_ARGUMENTS" ]; then
	cp --remove-destination "$(realpath "$TARGET_CFG")" "$TARGET_CFG"

	printf '%s\n' "$NS_EXTRA_ARGUMENTS" | sed 's/^[[:space:]]*//' | grep -E '^[+-]' | while read -r arg; do
		key=$(printf '%s' "$arg" | sed 's/^[+-]//' | awk '{print $1}')
		[ -n "$key" ] && sed -i "/^$key[ \t]/d" "$TARGET_CFG"
	done
fi

NS_EXTRA_ONELINE=""

if [ -n "$NS_EXTRA_ARGUMENTS" ]; then
	NS_EXTRA_ONELINE=$(printf '%s' "$NS_EXTRA_ARGUMENTS" | tr '\n' ' ')
fi

eval "exec nix shell /catornot-catornot-flakes#nswine --impure --command nix run /catornot-catornot-flakes#nswrap --impure -- -dedicated -port $PORT $NS_EXTRA_ONELINE"