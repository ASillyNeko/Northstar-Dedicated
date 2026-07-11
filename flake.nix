{
  description = "Northstar-Dedicated docker image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      nswine =
        let
          wine-ns = pkgs.wine64Packages.minimal.override { tlsSupport = true; };
          wine-stable = pkgs.wine64Packages.stable;

          nswine-go = pkgs.buildGoModule {
            pname = "nswine";
            version = "1.0.0";
            src = ./pg9182-nsdockerwine2/nswine;
            vendorHash = "sha256-RFOeqr9hvj/WWY19solDAMhajzqtQ82+2SDw5ce6zhI=";
          };

          patchthething =
            pkgs.writers.writeRustBin "patchthething" { } # rust
              ''
                use std::path::PathBuf;
                use std::env;
                use std::fs::{write,read};
                use std::error::Error;

                const REPLACE: &str = "mac,x11,wayland\x00";
                const NULL: &str = "null\x00";

                fn main() -> Result<(), Box<dyn Error>> {
                  let mut args = env::args();
                  _ = args.next();
                  let path_arg = PathBuf::from(args.next().ok_or("yes")?.to_string());

                  let replace = REPLACE.encode_utf16().flat_map(|b| b.to_ne_bytes()).collect::<Vec<u8>>();
                  let null = NULL.encode_utf16().flat_map(|b| b.to_ne_bytes()).collect::<Vec<u8>>();


                  let mut buf = read(&path_arg)?;
                  let index = buf.iter().enumerate().position(|(i,_)| buf.get(i..i + replace.len()).and_then(|slice| Some(slice == replace.as_slice()) ).unwrap_or_default() ).ok_or("skill issue")?;

                  _ = buf.drain(index..index + replace.len());

                  for b in 0..replace.len().saturating_sub(null.len()) {
                    buf.insert(index, 0);
                  }

                  for b in null.iter().copied().rev() {
                    buf.insert(index, b);
                  }
                  
                  write(&path_arg, buf)?;

                  Ok(())
                }
              '';

        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "nswine";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = [
            nswine-go
            pkgs.removeReferencesTo
          ];
          buildInputs = [
          ];

          phases = [ "buildPhase" ];

          buildPhase = "
              export XDG_CACHE_HOME=\"\$(mktemp -d)\"
              export HOME=\"\$(mktemp -d)\"

              mkdir $out
              cp -r --no-preserve=ownership ${wine-ns}/* $out
              chmod -R +rwXrwXrwX $out
              cp ${wine-stable}/lib/wine/x86_64-windows/explorer.exe $out/lib/wine/x86_64-windows/explorer.exe

              mkdir -p $TMP/wine
              mkdir -p $TMP/lib/wine/x86_64-windows

              NSWINE_UNSAFE=1 nswine --prefix $out --output $TMP/wine -debug -optimize

              ${pkgs.lib.getExe patchthething} $out/lib/wine/x86_64-windows/explorer.exe

              ! diff ${wine-ns}/share/wine/wine.inf $out/share/wine/wine.inf

              find $out -type f | xargs -r remove-references-to -t ${wine-ns} -t ${wine-stable}
          ";
        };

      nswrap = pkgs.stdenv.mkDerivation {
        pname = "nswrap";
        version = "1.0.0";

        src = ./pg9182-nsdockerwine2;

        nativeBuildInputs = [
        ];
        buildInputs = [
        ];

        phases = [ "buildPhase" ];

        buildPhase = ''
          mkdir -p $out/bin/
          gcc -Wall -Wextra $src/nswrap/nswrap.c -o $out/bin/nswrap
        '';

        meta = {
          mainProgram = "nswrap";
        };
      };

      alpineDigest = builtins.head (
        builtins.match ".*ALPINE_DIGEST=([^ ]+).*" (
          builtins.replaceStrings [ "\n" ] [ " " ] (builtins.readFile ./versions.sh)
        )
      );
      alpineSha256sum = builtins.head (
        builtins.match ".*ALPINE_SHA256SUM=([^ ]+).*" (
          builtins.replaceStrings [ "\n" ] [ " " ] (builtins.readFile ./versions.sh)
        )
      );

      northstarVersion = builtins.head (
        builtins.match ".*NORTHSTAR_VERSION=([^ ]+).*" (
          builtins.replaceStrings [ "\n" ] [ " " ] (builtins.readFile ./versions.sh)
        )
      );
      northstarSha256sum = builtins.head (
        builtins.match ".*NORTHSTAR_SHA256SUM=([^ ]+).*" (
          builtins.replaceStrings [ "\n" ] [ " " ] (builtins.readFile ./versions.sh)
        )
      );

      northstar = pkgs.stdenv.mkDerivation {
        name = "northstar-${northstarVersion}";

        src = pkgs.fetchurl {
          url = "https://github.com/R2Northstar/Northstar/releases/download/${northstarVersion}/Northstar.release.${northstarVersion}.zip";
          sha256 = "${northstarSha256sum}";
        };

        nativeBuildInputs = [ pkgs.unzip ];
        unpackPhase = "unzip $src -d $out";
      };

      entrypoint = pkgs.runCommand "entrypoint.sh" { } ''
        cp ${./entrypoint.sh} $out
        chmod +x $out
        substituteInPlace $out \
          --replace '/home/northstar/nswine/bin' '${nswine}/bin' \
          --replace '/home/northstar/nswrap/bin/nswrap' '${nswrap}/bin/nswrap'
      '';

    in
    {
      packages.x86_64-linux.default = pkgs.dockerTools.buildLayeredImage {
        name = "ghcr.io/asillyneko/northstar-dedicated";
        tag = "latest";

        # latest
        fromImage = pkgs.dockerTools.pullImage {
          imageName = "alpine";
          imageDigest = alpineDigest;
          sha256 = alpineSha256sum;
        };

        contents = [
          nswine
          nswrap
        ];

        extraCommands = ''
          mkdir -p home/northstar mnt/northstar
          cp -r ${northstar}/* mnt/northstar/
          rm -r /mnt/northstar/R2Northstar/mods/Northstar.Custom/mod/paks /mnt/northstar/R2Northstar/mods/Northstar.Custom/mod/vpk /mnt/northstar/R2Northstar/mods/Northstar.Custom/mod/models/northstartree
        '';

        config = {
          Env = [
            "WINEPREFIX=/home/northstar/.wine"
            "NSWRAP_EXTWINE=1"
          ];
          WorkingDir = "/home/northstar";
          Entrypoint = [ "${entrypoint}" ];
        };
      };
    };
}
