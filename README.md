# Northstar-Dedicated

> [!WARNING]
> THIS IMAGE IS UNTESTED/UNSUPPORTED ON WINDOWS, AND MAC OS, THIS IMAGE SHOULD ONLY BE USED ON LINUX

Barebones example `compose.yaml`

```yaml
services:
  northstar-dedicated:
    image: ghcr.io/asillyneko/northstar-dedicated
    pull_policy: always
    network_mode: host # DO NOT REMOVE
    tty: true
    stdin_open: true
    environment:
      - NS_PORT=37016
      - NSWRAP_NOWATCHDOGQUIT=0 # Set to 1 if ns_report_server_to_masterserver is set to 0
      - |
        NS_EXTRA_ARGUMENTS=
        +ns_server_name "Example Barebones Northstar Docker Server"
        +ns_server_desc "Example Server Desc https://northstar.tf"
        -multiple
    volumes:
      - /home/neko/northstar/titanfall2-files:/mnt/titanfall2:ro
    restart: always
```

Skirmish example `compose.yaml`

```yaml
services:
  northstar-dedicated:
    image: ghcr.io/asillyneko/northstar-dedicated
    pull_policy: always
    network_mode: host # DO NOT REMOVE
    tty: true
    stdin_open: true
    environment:
      - NS_PORT=37016
      - NSWRAP_NOWATCHDOGQUIT=0 # Set to 1 if ns_report_server_to_masterserver is set to 0
      - |
        NS_EXTRA_ARGUMENTS=
        +ns_server_name "Example Skirmish Northstar Docker Server"
        +ns_server_desc "Example Server Desc https://northstar.tf"
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
        +sv_max_props_multiplayer 500000
        +sv_max_prop_data_dwords_multiplayer 800000
        +net_chan_limit_msec_per_sec 500
        +net_compresspackets 1
        +net_compresspackets_minsize 64
        -enablechathooks
        -allowlocalhttp
        -multiple
        -nopakdedi
    volumes:
      - /home/neko/northstar/titanfall2-files:/mnt/titanfall2:ro
      - /home/neko/northstar/Attrition-Extended-Recode-Mods:/mnt/mods/:ro
      - /home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/plugins:ro
      - /home/neko/northstar/Attrition-Extended-Recode-Save-Data:/mnt/northstar/R2Northstar/save_data
    restart: always
```

## Titanfall 2
You can use a normal Titanfall 2 install or you can shrink the Titanfall 2 install

### Reducing Titanfall 2 size
> [!WARNING]
> ONLY DO THIS TO NORTHSTAR-DEDICATED TITANFALL 2 INSTALL DO NOT DO THIS TO YOUR ACTUAL TITANFALL 2 INSTALL

Normal size 64GB

The following files/folders can be deleted on any Northstar-Dedicated server install:

`vpk/client_sp_*` and `vpk/englishclient_sp_*` (12GB)
`r2/sound/general*` (4.8GB)
`r2/maps/*` and recreate `r2/maps/graphs` directory (1.5GB)
`r2/media` (1.1GB)
`__Installer` (343MB)
`Core` (42MB)
`bin/x64_retail/client.dll` (13MB)

If you use the `-nopakdedi` launch argument you can safely delete `r2/paks/Win64/*` (42GB) note removing `-nopakdedi` later will need these removed files

If you're not using `-nopakdedi` you can delete these:

`r2/paks/Win64/pc_*` (38.0GB)
`r2/paks/Win64/sp_*` (1.6GB)

New size 6.0GB with `-nopakdedi` 8.1GB without `-nopakdedi`

## Configuration
You can run commands on startup by doing `+command_name value` like `+setplaylist tdm` or `+map mp_forwardbase_kodai` in `NS_EXTRA_ARGUMENTS`

You can change the values of convars by doing `+convar_name "new value"` quotes aren't needed but if you have `//` in the new value it'll be cut off for example
`+somerandom_convar https://northstar.tf` becomes `https:` but with quotes `+convar_name "https://northstar.tf"` it becomes `https://northstar.tf`
`+ns_allow_team_change 0` it becomes `0` and with quotes `+ns_allow_team_change "0"` it's still `0`

You can add launch args by doing `-launcharg` like `-multiple` or `-nopakdedi`

It's recommended to set `NS_PORT` to a port between `37016` and `37041` although you can set it to something like `37042`

### Volumes
> [!NOTE]
> Replace /home/neko/northstar with the directory where your files are located on your host machine.

`:ro` makes that volume read only in the docker container

#### Required Volumes

##### Titanfall 2 install
- `- /home/neko/northstar/titanfall2-files:/mnt/titanfall2:ro` Needed to run dedicated server (Should always have `:ro`)

#### Optional Volumes

##### Custom northstar install
- `- /home/neko/northstar/Attrition-Extended-Recode:/mnt/northstar` Replaces files in northstar with ones in that directory. (Should never have `:ro`)

##### Mods
- `- /home/neko/northstar/Attrition-Extended-Recode-Mods:/mnt/mods/:ro` Adds all the mods in this directory. (Should always have `:ro`)
- `- /home/neko/northstar/Attrition-Extended-Recode-Mods/Nekos.Attrition.Extended.Recode:/mnt/mods/Nekos.Attrition.Extended.Recode:ro` Adds this mod. (Should always have `:ro`)
- `- /home/neko/northstar/Attrition-Extended-Recode-Mods:/mnt/northstar/R2Northstar/mods/:ro` Replaces all the mods in this directory including built-in mods. (Should always have `:ro`)

##### Plugins
- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/plugins:ro` Adds all the plugins in this directory. (Should always have `:ro`)
- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins/bp-ort.dll:/mnt/plugins/bp-ort.dll:ro` Adds this plugin. (Should always have `:ro`)
- `- /home/neko/northstar/Attrition-Extended-Recode-Plugins:/mnt/northstar/R2Northstar/plugins/:ro` Replaces all the plugins in this directory including built-in plugins. (Should always have `:ro`)

##### Save data
- `- /home/neko/northstar/Attrition-Extended-Recode-Save-Data:/mnt/northstar/R2Northstar/save_data` Reads and writes save data for mods, should be different for each server. (Should never have `:ro`)