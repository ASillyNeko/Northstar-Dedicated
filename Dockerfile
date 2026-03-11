FROM nixos/nix:2.34.1

ENV WINEPREFIX=/home/northstar/.wine
ENV NSWRAP_EXTWINE=1

WORKDIR /home/northstar

RUN mkdir -p /mnt/northstar

RUN nix-env -iA nixpkgs.curl nixpkgs.unzip nixpkgs.coreutils nixpkgs.gnused nixpkgs.gnugrep nixpkgs.gawk

COPY catornot-catornot-flakes/ ./catornot-catornot-flakes

RUN echo -e "experimental-features = nix-command flakes\ndownload-buffer-size = 536870912\nauto-optimise-store = true" >> /etc/nix/nix.conf && \
	nix build ./catornot-catornot-flakes#nswine -o nswine && \
	nix build ./catornot-catornot-flakes#nswrap -o nswrap && \
	nix-collect-garbage -d

RUN rm -r ./catornot-catornot-flakes

COPY northstar_version.sh ./northstar_version.sh

RUN chmod +x ./northstar_version.sh

RUN . ./northstar_version.sh && \
		curl -L https://github.com/R2Northstar/Northstar/releases/download/${NORTHSTAR_VERSION}/Northstar.release.${NORTHSTAR_VERSION}.zip -o northstar.zip && \
		sha256sum -c <(echo "${NORTHSTAR_GITHUB_SHA256SUM#sha256:} northstar.zip") && \
		unzip ./northstar.zip -d /mnt/northstar/ && \
		rm ./northstar.zip && \
		rm ./northstar_version.sh

RUN ln -sf $(which bash) /bin/bash

COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["/home/northstar/entrypoint.sh"]