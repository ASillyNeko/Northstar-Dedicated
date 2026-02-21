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
      - /home/neko/northstar/Attrition-Extended-Recode-Mods:/mnt/mods/:ro
      - /home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/plugins:ro
      - /home/neko/northstar/Attrition-Extended-Recode-Data:/northstar/R2Northstar/save_data
    restart: always
```

## Titanfall 2
You can use a normal Titanfall 2 install or you can shrink the Titanfall 2 install

### Reducing Titanfall 2 size

> [!WARNING]
> ONLY DO THIS FOR NORTHSTAR-DEDICATED DO NOT DO THIS FOR YOUR ACTUAL TITANFALL 2 INSTALL

Normal size 70.6GB

- delete `r2/paks/Win64/pc_*` (40.0GB)
- delete `vpk/client_sp_*` and `vpk/englishclient_sp_*` (12.2GB)
- delete `r2/sound/**` (5.1GB)
- delete `r2/paks/Win64/mp_*` (1.8GB)
- delete `r2/paks/Win64/sp_*` (1.7GB)
- delete `r2/maps/**` (1.5GB)
- delete `r2/media/**` (1.1GB)
- delete `__Installer/` (354MB)
- delete `Core/` (43MB)
- delete `bin/x64_retail/client.dll` (13MB)

## Configuration

Set `NSWRAP_NOWATCHDOGQUIT` to 1 if your server has `ns_report_server_to_masterserver 0`

### How to mount custom northstar install, mods, plugins, and save data of mods `volumes`

### Custom northstar install

- `- /home/neko/northstar/Attrition-Extended-Recode:/northstar` Replaces files in northstar with ones in that directory, DO NOT ADD `:ro` as `:ro` makes this volume read only and northstar needs to make a log file.

### Mods

- `- /home/neko/northstar/Attrition-Extended-Recode-Mods:/mnt/mods/:ro` Adds all the mods in this directory.
- `- /home/neko/northstar/Attrition-Extended-Recode-Mods/Nekos.Attrition.Extended.Recode:/mnt/mods/Nekos.Attrition.Extended.Recode:ro` Adds this mod.
- `- /home/neko/northstar/Attrition-Extended-Recode-Mods:/northstar/R2Northstar/mods/:ro` Replaces all the mods in this directory including built-in mods.

### Plugins

- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/plugins:ro` Adds all the plugins in this directory.
- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/plugins/bp-ort.dll:ro` Adds this plugin.
- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins:/northstar/R2Northstar/plugins/:ro` Replaces all the plugins in this directory including built-in plugins.

### Save data

- `- /home/neko/northstar/Attrition-Extended-Recode-Data:/northstar/R2Northstar/save_data` Reads and writes save data for mods, DO NOT ADD `:ro` as `:ro` makes this volume read only and northstar needs to make files for mods here