# Northstar-Dedicated

Example `docker-compose.yml`

```yaml
x-logging:
  &logging
  logging:
    driver: "json-file"
    options:
      max-file: "5"
      max-size: "400m"

services:
  Northstar:
    << : *logging
    container_name: Northstar
    image: ghcr.io/asillyneko/northstar-dedicated:latest
    network_mode: host # DO NOT REMOVE
    environment:
      - NS_PORT=37015
      - NSWRAP_NOWATCHDOGQUIT=0
      - |
        NS_EXTRA_ARGUMENTS=
        +ns_server_name "Unnamed Northstar Docker Server"
        +ns_server_desc ""
        -nopakdedi
    volumes:
      - /home/neko/northstar/titanfall2-files:/titanfall2:ro
    restart: always
```

# Configuration

Add `NSWRAP_NOWATCHDOGQUIT=1` if your server has `ns_report_server_to_masterserver 0` or is a singleplayer with `ns_report_sp_server_to_masterserver 0`

**Example ways to mount custom northstar install, mods, plugins, and save data of mods `volumes`**

**CUSTOM NORTHSTAR INSTALL**

- `/home/neko/northstar/Attrition-Extended-Recode:/northstar` Replaces files in northstar with ones in that directory, DO NOT ADD `:ro` as `:ro` makes this volume read only and northstar needs to make a log file.

**MODS**

- `/home/neko/northstar/Attrition-Extended-Recode-Mods:/mnt/mods/:ro` Adds all the mods in this directory.
- `/home/neko/northstar/Attrition-Extended-Recode-Mods/Nekos.Attrition.Extended.Recode:/mnt/mods/Nekos.Attrition.Extended.Recode:ro` Adds this mod.

**PLUGINS**

- `/home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/plugins:ro` Adds all the plugins in this directory.
- `/home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/plugins/bp-ort.dll:ro` Adds this plugin.

**SAVE DATA**

- `/home/neko/northstar/Attrition-Extended-Recode-Data:/northstar/R2Northstar/save_data` Reads and writes save data for mods, DO NOT ADD `:ro` as `:ro` makes this volume read only and northstar needs to make files for mods here