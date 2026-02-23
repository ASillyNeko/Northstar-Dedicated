# Northstar-Dedicated

Barebones example `docker-compose.yml`

```yaml
x-logging:
  &logging
  logging:
    driver: "json-file"
    options:
      max-file: "5"
      max-size: "400m"

services:
  Northstar-Dedicated:
    << : *logging
    image: ghcr.io/asillyneko/northstar-dedicated:latest
    network_mode: host # DO NOT REMOVE
    tty: true
    stdin_open: true
    environment:
      - NS_PORT=37016
      - NSWRAP_NOWATCHDOGQUIT=0
      - |
        NS_EXTRA_ARGUMENTS=
        +ns_server_name "Example Barebones Northstar Docker Server"
        +ns_server_desc "Example Server Desc"
        -nopakdedi
    volumes:
      - /home/neko/northstar/titanfall2-files:/titanfall2:ro
    restart: always
```

Skirmish Example

```yaml
x-logging:
  &logging
  logging:
    driver: "json-file"
    options:
      max-file: "5"
      max-size: "400m"

services:
  Northstar-Dedicated:
    << : *logging
    image: ghcr.io/asillyneko/northstar-dedicated:latest
    network_mode: host # DO NOT REMOVE
    tty: true
    stdin_open: true
    environment:
      - NS_PORT=37016
      - NSWRAP_NOWATCHDOGQUIT=0
      - |
        NS_EXTRA_ARGUMENTS=
        +ns_server_name "Example Skirmish Northstar Docker Server"
        +ns_server_desc "Example Server Desc"
        +setplaylist tdm
        +mp_gamemode tdm
        +map mp_forwardbase_kodai
        +ns_private_match_last_map mp_forwardbase_kodai
        +ns_private_match_only_host_can_start 1
        +ns_private_match_only_host_can_change_settings 2
        +ns_private_match_last_mode tdm
        +ns_should_return_to_lobby 0
        +ns_allow_team_change 0
        +setplaylistvaroverrides "max_players 16 timelimit 15 scorelimit 1500"
        +sv_minupdaterate 60
        +spewlog_enable 0
        +sv_max_props_multiplayer 500000
        +sv_max_prop_data_dwords_multiplayer 800000
        +net_chan_limit_msec_per_sec 500
        +net_compresspackets 1
        +net_compresspackets_minsize 32
        +base_tickinterval_mp 0.016666667
        +rate 786432
        +sv_updaterate_mp 60
        +sv_minupdaterate 60
        +sv_max_snapshots_multiplayer 900
        -enablechathooks
        -allowlocalhttp
        -multiple
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
> ONLY DO THIS FOR NORTHSTAR-DEDICATED DO NOT DO THIS TO YOUR ACTUAL TITANFALL 2 INSTALL

Normal size 70.6GB

- delete `r2/paks/Win64/pc_*` (40.0GB)
- delete `vpk/client_sp_*` and `vpk/englishclient_sp_*` (12.2GB)
- delete `r2/sound/general*` (5.1GB)
- delete `r2/paks/Win64/mp_*` (1.8GB)
- delete `r2/paks/Win64/sp_*` (1.7GB)
- delete `r2/maps/*` (1.5GB)
- delete `r2/media/*` (1.1GB)
- delete `r2/ui/*` (539MB)
- delete `__Installer/` (354MB)
- delete `Core/` (43MB)
- delete `bin/x64_retail/client.dll` (13MB)

New size 6.3GB

## Configuration
You can change values of convars by doing `+convar_name "new value"` quotes aren't needed but if you have `//` in the new value it'll be cut off example
`+somerandom_convar https://ds.asillyneko.dev` becomes `https:` but with quotes `+convar_name "https://ds.asillyneko.dev"` becomes `https://ds.asillyneko.dev`
`+ns_allow_team_change 0` becomes `0` and with quotes `+ns_allow_team_change "0"` is still `0`

You can add launch args by doing `-launcharg` like `-multiple` or `-nopakdedi`

Set `NS_PORT` to a port between `37016` and `37041`

Set `NSWRAP_NOWATCHDOGQUIT` to 1 if your server has `ns_report_server_to_masterserver 0`

### Volumes

### Custom northstar install
- `- /home/neko/northstar/Attrition-Extended-Recode:/northstar` Replaces files in northstar with ones in that directory, DO NOT ADD `:ro` as `:ro` makes this volume read only and northstar needs to make a log file.

### Mods
- `- /home/neko/northstar/Attrition-Extended-Recode-Mods:/mnt/mods/:ro` Adds all the mods in this directory.
- `- /home/neko/northstar/Attrition-Extended-Recode-Mods/Nekos.Attrition.Extended.Recode:/mnt/mods/Nekos.Attrition.Extended.Recode:ro` Adds this mod.
- `- /home/neko/northstar/Attrition-Extended-Recode-Mods:/northstar/R2Northstar/mods/:ro` Replaces all the mods in this directory including built-in mods.

### Plugins
- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/plugins:ro` Adds all the plugins in this directory.
- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins/bp-ort.dll:/mnt/plugins/bp-ort.dll:ro` Adds this plugin.
- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins:/northstar/R2Northstar/plugins/:ro` Replaces all the plugins in this directory including built-in plugins.

### Save data
- `- /home/neko/northstar/Attrition-Extended-Recode-Data:/northstar/R2Northstar/save_data` Reads and writes save data for mods, DO NOT ADD `:ro` as `:ro` makes this volume read only and northstar needs to make files for mods here