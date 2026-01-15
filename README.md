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
      - |
        NS_EXTRA_ARGUMENTS=
        +ns_server_name "Unnamed Northstar Server"
        +ns_server_desc ""
    volumes:
      - /home/neko/northstar/titanfall2-files:/titanfall2
      - /home/neko/northstar/Attrition-Extended-Recode:/northstar
    restart: always
```

If Your Server Has `ns_report_server_to_masterserver 0` Or Is A Singleplayer With `ns_report_sp_server_to_masterserver 0` Use `NSWRAP_NOWATCHDOGQUIT=1` Otherwise It'll Quit

If You Want To Edit The `R2Northstar/mods/Northstar.CustomServers/mod/cfg/autoexec_ns_server.cfg` Use The `autoexec_ns_server.cfg.bak` Version Not `autoexec_ns_server.cfg` As It Gets Overwritten