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
		-disablelogs
    volumes:
      - /home/neko/northstar/Attrition-Extended-Recode:/titanfall2
    restart: always
```

Don't Remove `network_mode: host`

Your Location For `titanfall2` Should Look Like

```shell
neko@nekoserver:~/northstar/Attrition-Extended-Recode$ ls -al
total 20816
drwxr-xr-x  7 neko neko     4096 Dec 25 07:12 .
drwxrwxrwx 10 neko neko     4096 Dec 25 07:19 ..
-rwxr-xr-x  1 neko neko  5051392 Dec 24 03:53 Northstar.dll
-rwxr-xr-x  1 neko neko  2542592 Dec 24 03:53 NorthstarLauncher.exe
drwxr-xr-x  7 neko neko     4096 Nov 14 18:47 R2Northstar
drwxr-xr-x  4 neko neko     4096 Nov 14 17:21 bin
-rwxr-xr-x  1 neko neko        9 Dec 13 17:37 ns_startup_args.txt
-rwxr-xr-x  1 neko neko     1020 Dec 19 16:49 ns_startup_args_dedi.txt
drwxr-xr-x  4 neko neko     4096 Dec 13 17:37 r2
-rwxr-xr-x  1 neko neko 13680184 Dec  5  2017 server.dll
drwxr-xr-x  2 neko neko     4096 Dec  1 14:40 vpk
```