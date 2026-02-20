FROM nixos/nix:2.33.3

RUN mkdir -p /etc/nix && \
	echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

ENV SYMLINK_TITANFALL2_FILES=0
ENV SYMLINK_NORTHSTAR_FILES=0
ENV WINEPREFIX=/wine/wine
ENV NSWRAP_EXTWINE=1

RUN mkdir -p /wine/wine && mkdir -p /northstar

COPY northstar_version.sh /northstar_version.sh

RUN chmod +x /northstar_version.sh

RUN nix-env -iA nixpkgs.curl nixpkgs.unzip nixpkgs.coreutils

RUN . /northstar_version.sh && \
	curl -L https://github.com/R2Northstar/Northstar/releases/download/${NORTHSTAR_VERSION}/Northstar.release.${NORTHSTAR_VERSION}.zip -o northstar.zip && \
	sha256sum -c <(echo "${NORTHSTAR_GITHUB_SHA256SUM#sha256:}  northstar.zip") && \
	unzip northstar.zip -d /northstar/ && \
	rm northstar.zip

WORKDIR /build

COPY catornot-catornot-flakes/ ./catornot-catornot-flakes

RUN nix-env -iA nixpkgs.gnused nixpkgs.gawk && \
	nix build ./catornot-catornot-flakes#nswine-env && \
	nix build ./catornot-catornot-flakes#nswrap && \
	rm -rf ./catornot-catornot-flakes/

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]