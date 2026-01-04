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
    network_mode: host
    environment:
      - NS_PORT=37015
      - |
        NS_EXTRA_ARGUMENTS=
        +ns_server_name "Unnamed Northstar Server"
        +ns_server_desc ""
    volumes:
      - .:/titanfall2
    restart: always
```

Add `NSWRAP_NOWATCHDOGQUIT=1` If You Use `-disablelogs` Otherwise It Will Quit Randomly Probably Shouldn't Use `-disablelogs` Anyways

Don't Remove `network_mode: host`

Your Location For `titanfall2` Should Look Like

```shell
neko@nekoserver:~/northstar/Attrition-Extended-Recode$ ls -al
total 20812
drwxr-xr-x 6 neko neko     4096 Dec 25 10:20 .
drwxrwxrwx 8 neko neko     4096 Dec 25 10:21 ..
-rwxr-xr-x 1 neko neko  5051392 Dec 24 03:53 Northstar.dll
-rwxr-xr-x 1 neko neko  2542592 Dec 24 03:53 NorthstarLauncher.exe
drwxr-xr-x 7 neko neko     4096 Nov 14 18:47 R2Northstar
drwxr-xr-x 4 neko neko     4096 Nov 14 17:21 bin
-rwxr-xr-x 1 root root     1568 Dec 25 10:20 docker-compose.yml
-rwxr-xr-x 1 neko neko        9 Dec 13 17:37 ns_startup_args.txt
-rwxr-xr-x 1 neko neko        0 Dec 25 10:24 ns_startup_args_dedi.txt
drwxr-xr-x 4 neko neko     4096 Dec 13 17:37 r2
-rwxr-xr-x 1 neko neko 13680184 Dec  5  2017 server.dll
drwxr-xr-x 2 neko neko     4096 Dec  1 14:40 vpk
```