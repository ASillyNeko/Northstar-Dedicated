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
  northstar:
    << : *logging
    image: ghcr.io/asillyneko/northstar-dedicated:latest
    network_mode: host # DO NOT REMOVE
    environment:
      - NS_PORT=37015
      - SYMLINK_TITANFALL2_FILES=0 # Set this to 1 if you want to save disk space but you risk getting Data Execution Prevention (DEP) crashes if multiple servers use the same directory
      - SYMLINK_NORTHSTAR_FILES=0 # Set this to 1 if you want to save disk space but you risk getting Data Execution Prevention (DEP) crashes if multiple servers use the same directory
      - NSWRAP_NOWATCHDOGQUIT=0 # Set this to 1 if your server has ns_report_server_to_masterserver 0 or is a singleplayer with ns_report_sp_server_to_masterserver 0
      - |
        NS_EXTRA_ARGUMENTS=
        +ns_server_name "Unnamed Northstar Docker Server"
        +ns_server_desc ""
    volumes:
      - /home/neko/northstar/titanfall2-files:/titanfall2
      # Example ways to mount northstar/mods:
      # - /home/neko/northstar/Attrition-Extended-Recode:/northstar # Replaces files in northstar with ones in that directory
      # - /home/neko/northstar/Attrition-Extended-Recode-Mods:/northstar/R2Northstar/mods # Replaces files only in mods folder with ones in that directory
      # - /home/neko/northstar/Attrition-Extended-Recode-Mods/Nekos.Attrition.Extended.Recode:/northstar/R2Northstar/mods/Nekos.Attrition.Extended.Recode # Adds this mod
    restart: always
```

If You Want To Edit The `R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg` Use The `autoexec_ns_server.cfg.bak` Version Not `autoexec_ns_server.cfg` As It Gets Overwritten