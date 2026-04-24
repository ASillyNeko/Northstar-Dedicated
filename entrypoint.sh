#!/bin/sh
set -e

TF2_DIR=/mnt/titanfall2
NORTHSTAR_DIR=/mnt/northstar
CONVAR_SETTER_DIR=/mnt/Nekos.Northstar.Dedicated.Convar.Setter
MODS_DIR=/mnt/mods
PLUGINS_DIR=/mnt/plugins
TMP_DIR=/tmp/northstar

if [ -d "$TMP_DIR/" ]; then
	rm -r "$TMP_DIR"
fi

mkdir -p "$TMP_DIR"

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

for file in "$TF2_DIR"/* "$NORTHSTAR_DIR"/*; do
	[ -e "$file" ] || continue

	basename=$(basename "$file")

	[ "$basename" != "R2Northstar" ] || continue
	[ "$basename" != "bin" ] || continue
	[ "$basename" != "ns_startup_args_dedi.txt" ] || continue

	ln -sfn "$file" "$TMP_DIR/$basename"
done

mkdir -p "$TMP_DIR/R2Northstar"

for file in "$NORTHSTAR_DIR/R2Northstar"/*; do
	[ -e "$file" ] || continue

	basename=$(basename "$file")

	[ "$basename" != "mods" ] || continue
	[ "$basename" != "plugins" ] || continue

	ln -sfn "$file" "$TMP_DIR/R2Northstar/$basename"
done

mkdir -p "$TMP_DIR/R2Northstar/mods/Northstar.CustomServers/mod/cfg"
cp "$NORTHSTAR_DIR/R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg" "$TMP_DIR/R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg"

for file in "$NORTHSTAR_DIR/R2Northstar/mods"/*; do
	[ -e "$file" ] || continue

	basename=$(basename "$file")

	[ "$basename" != "Northstar.CustomServers" ] || continue

	ln -sfn "$file" "$TMP_DIR/R2Northstar/mods/$basename"
done

for file in "$NORTHSTAR_DIR/R2Northstar/mods/Northstar.CustomServers"/*; do
	[ -e "$file" ] || continue

	basename=$(basename "$file")

	[ "$basename" != "mod" ] || continue

	ln -sfn "$file" "$TMP_DIR/R2Northstar/mods/Northstar.CustomServers/$basename"
done

for file in "$NORTHSTAR_DIR/R2Northstar/mods/Northstar.CustomServers/mod"/*; do
	[ -e "$file" ] || continue

	basename=$(basename "$file")

	[ "$basename" != "cfg" ] || continue

	ln -sfn "$file" "$TMP_DIR/R2Northstar/mods/Northstar.CustomServers/mod/$basename"
done

for file in "$NORTHSTAR_DIR/R2Northstar/mods/Northstar.CustomServers/mod/cfg"/*; do
	[ -e "$file" ] || continue

	basename=$(basename "$file")

	[ "$basename" != "autoexec_ns_server.cfg" ] || continue

	ln -sfn "$file" "$TMP_DIR/R2Northstar/mods/Northstar.CustomServers/mod/cfg/$basename"
done

mkdir -p "$TMP_DIR/R2Northstar/plugins"

for file in "$NORTHSTAR_DIR/R2Northstar/plugins"/*; do
	[ -e "$file" ] || continue

	basename=$(basename "$file")

	ln -sfn "$file" "$TMP_DIR/R2Northstar/plugins/$basename"
done

mkdir -p "$TMP_DIR/bin"

for file in "$TF2_DIR/bin"/* "$NORTHSTAR_DIR/bin"/*; do
	[ -e "$file" ] || continue

	basename=$(basename "$file")

	if [ -d "$file" ]; then
		mkdir -p "$TMP_DIR/bin/$basename"

		for otherfile in "$file"/*; do
			[ -e "$otherfile" ] || continue

			otherbasename=$(basename "$otherfile")

			ln -sfn "$otherfile" "$TMP_DIR/bin/$basename/$otherbasename"
		done
	else
		ln -sfn "$file" "$TMP_DIR/bin/$basename"
	fi
done

cp -r "$CONVAR_SETTER_DIR" "$TMP_DIR/R2Northstar/mods/Nekos.Northstar.Dedicated.Convar.Setter"

{
	printf 'global const table< string, string > northstar_dedicated_convars = {\n'

	if [ -n "$NS_CONVARS" ]; then
		printf '%s\n' "$NS_CONVARS" | sed 's/^[[:space:]]*//' | grep -E '^[a-zA-Z_]' | while read -r line; do
			key=$(printf '%s' "$line" | awk -F '[[:space:]]*=[[:space:]]*' '{print $1}')
			value=$(printf '%s' "$line" | sed 's/^[^=]*=[[:space:]]*//' | sed 's/^"\(.*\)"$/\1/')
			printf '\t%s = "%s",\n' "$key" "$value"
		done
	fi

	printf '}'
} > "$TMP_DIR/R2Northstar/mods/Nekos.Northstar.Dedicated.Convar.Setter/mod/scripts/vscripts/convars.nut"

if [ -d "$MODS_DIR" ]; then
	for file in "$MODS_DIR"/*/; do
		[ -d "$file" ] || continue

		basename=$(basename "$file")
		target="$TMP_DIR/R2Northstar/mods/$basename"

		if [ -e "$target" ] || [ -L "$target" ]; then
			echo "Error: cannot overwrite built-in mod/file, '$basename'"
			echo "Change your volume to '$NORTHSTAR_DIR/R2Northstar/mods:ro' if you want to overwrite built-in mods/files"
			exit 1
		fi

		ln -sfn "$file" "$target"
	done
fi

if [ -d "$PLUGINS_DIR" ]; then
	for file in "$PLUGINS_DIR"/*; do
		[ -f "$file" ] || continue

		basename=$(basename "$file")
		target="$TMP_DIR/R2Northstar/plugins/$basename"

		if [ -e "$target" ] || [ -L "$target" ]; then
			echo "Error: cannot overwrite built-in plugin/file, '$basename'"
			echo "Change your volume to '$NORTHSTAR_DIR/R2Northstar/plugins:ro' if you want to overwrite built-in plugins/files"
			exit 1
		fi

		ln -sfn "$file" "$target"
	done
fi

cd "$TMP_DIR"

PORT=${NS_PORT:-37016}
TARGET_CFG="$TMP_DIR/R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg"

if [ -n "$NS_EXTRA_ARGUMENTS" ]; then
	printf '%s\n' "$NS_EXTRA_ARGUMENTS" | sed 's/^[[:space:]]*//' | grep -E '^[+-]' | while read -r arg; do
		key=$(printf '%s' "$arg" | sed 's/^[+-]//' | awk '{print $1}')

		[ -n "$key" ] && sed -i "/^$key[ \t]/d" "$TARGET_CFG"
	done
fi

if [ -n "$NS_EXTRA_ARGUMENTS" ]; then
	printf '%s' "$NS_EXTRA_ARGUMENTS" | tr '\n' ' ' > "$TMP_DIR/ns_startup_args_dedi.txt"
else
	printf '%s' "+setplaylist private_match" > "$TMP_DIR/ns_startup_args_dedi.txt"
fi

export PATH=/home/northstar/nswine/bin:$PATH

/home/northstar/nswrap/bin/nswrap -dedicated -port "$PORT"