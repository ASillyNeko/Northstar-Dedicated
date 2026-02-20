FROM nixos/nix:2.33.3

ENV WINEPREFIX=/wine/wine
ENV NSWRAP_EXTWINE=1

WORKDIR /build

RUN mkdir -p /wine/wine && mkdir -p /northstar

COPY northstar_version.sh /northstar_version.sh

RUN chmod +x /northstar_version.sh

RUN nix-env -iA nixpkgs.curl nixpkgs.unzip nixpkgs.coreutils nixpkgs.gnused nixpkgs.gnugrep nixpkgs.gawk

RUN . /northstar_version.sh && \
	curl -L https://github.com/R2Northstar/Northstar/releases/download/${NORTHSTAR_VERSION}/Northstar.release.${NORTHSTAR_VERSION}.zip -o northstar.zip && \
	sha256sum -c <(echo "${NORTHSTAR_GITHUB_SHA256SUM#sha256:}  northstar.zip") && \
	unzip ./northstar.zip -d /northstar/ && \
	rm ./northstar.zip && \
	rm /northstar_version.sh

COPY catornot-catornot-flakes/ /catornot-catornot-flakes

RUN mkdir -p /etc/nix && \
	echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
	nix build /catornot-catornot-flakes#nswine -o /nswine && \
	nix build /catornot-catornot-flakes#nswrap -o /nswrap && \
	nix-collect-garbage -d && \
	nix build /catornot-catornot-flakes#nswine -o /nswine && \
	nix build /catornot-catornot-flakes#nswrap -o /nswrap && \
	nix-store --optimise

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]