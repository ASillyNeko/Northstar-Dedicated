FROM nixos/nix:2.33.1

RUN mkdir -p /etc/nix && \
	echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

ENV TF2_DIR=/titanfall2
ENV NORTHSTAR_DIR=/northstar
ENV WINEPREFIX=/wine/wine
ENV NSWRAP_EXTWINE=1

RUN mkdir -p /wine/wine && mkdir -p /northstar
COPY get_northstar_version.sh /get_northstar_version.sh

RUN chmod +x /get_northstar_version.sh

RUN nix-env -iA nixpkgs.curl nixpkgs.unzip nixpkgs.coreutils

RUN . /get_northstar_version.sh && \
	curl -L https://github.com/R2Northstar/Northstar/releases/download/${NORTHSTAR_VERSION}/Northstar.release.${NORTHSTAR_VERSION}.zip -o northstar.zip && \
	sha256sum -c <(echo "${NORTHSTAR_GITHUB_SHA256SUM#sha256:}  northstar.zip") && \
	unzip northstar.zip -d /northstar/ && \
	rm northstar.zip

WORKDIR /build

RUN nix-env -iA nixpkgs.gnused nixpkgs.gawk && \
	nix-collect-garbage -d

RUN nix build github:catornot/catornot-flakes#nswine && \
	nix build github:catornot/catornot-flakes#nswrap

RUN rm -rf /root/.cache /tmp/* /var/cache/* /var/tmp/*

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]