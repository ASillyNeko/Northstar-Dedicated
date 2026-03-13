FROM ubuntu:25.10

ENV WINEPREFIX=/home/northstar/.wine
ENV NSWRAP_EXTWINE=1

WORKDIR /home/northstar

RUN apt-get update && \
	apt-get install curl xz-utils unzip -y && \
	rm -rf /var/lib/apt/lists/* && \
	curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install -o ./nix-install.sh && \
	sh ./nix-install.sh --daemon --yes && \
	rm ./nix-install.sh

ENV PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

RUN mkdir -p /mnt/northstar

COPY catornot-catornot-flakes/ ./catornot-catornot-flakes

RUN printf "experimental-features = nix-command flakes\ndownload-buffer-size = 536870912\nauto-optimise-store = true" >> /etc/nix/nix.conf && \
	nix build ./catornot-catornot-flakes#nswine -o nswine && \
	nix build ./catornot-catornot-flakes#nswrap -o nswrap && \
	nix-collect-garbage -d && \
	rm -r ./catornot-catornot-flakes

COPY northstar_version.sh ./northstar_version.sh

RUN chmod +x ./northstar_version.sh

RUN . ./northstar_version.sh && \
		curl -L https://github.com/R2Northstar/Northstar/releases/download/${NORTHSTAR_VERSION}/Northstar.release.${NORTHSTAR_VERSION}.zip -o northstar.zip && \
		printf "${NORTHSTAR_GITHUB_SHA256SUM#sha256:}  northstar.zip" | sha256sum -c && \
		unzip ./northstar.zip -d /mnt/northstar/ && \
		rm ./northstar.zip && \
		rm ./northstar_version.sh

COPY entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["/home/northstar/entrypoint.sh"]