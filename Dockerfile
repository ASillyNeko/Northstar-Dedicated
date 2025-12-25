FROM nixos/nix:2.20.5

RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

ENV TF2_DIR=/titanfall2
ENV WINEPREFIX=/wine/wine
ENV NSWRAP_EXTWINE=1
ENV NSWRAP_NOWATCHDOGQUIT=1

RUN mkdir -p /wine/wine && mkdir -p /etc/northstar

COPY <<EOF /etc/northstar/autoexec_ns_server.cfg
ns_server_name "Unnamed Northstar Server"
ns_server_desc "Default server description"
ns_server_password ""
ns_report_server_to_masterserver 1
ns_report_sp_server_to_masterserver 0
ns_auth_allow_insecure 0
ns_erase_auth_info 1
ns_masterserver_hostname "https://northstar.tf"
everything_unlocked 1
ns_should_return_to_lobby 1
net_chan_limit_mode 2
net_chan_limit_msec_per_sec 100
sv_querylimit_per_sec 15
base_tickinterval_mp 0.016666667
sv_updaterate_mp 20
sv_minupdaterate 20
sv_max_snapshots_multiplayer 300
net_data_block_enabled 0
host_skip_client_dll_crc 1
announcementVersion 1
announcement #PROGRESSION_ANNOUNCEMENT_BODY
EOF

WORKDIR /build

RUN nix-env -iA nixpkgs.gnused nixpkgs.gawk && \
    nix build github:catornot/catornot-flakes#nswine-env && \
    nix-collect-garbage -d && \
    rm -rf /root/.cache /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]