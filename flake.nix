{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    catornot-flakes.url= "path:./catornot-catornot-flakes";
  };

  outputs = { self, nixpkgs, catornot-flakes }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    nswine = catornot-flakes.packages.x86_64-linux.nswine;
    nswrap = catornot-flakes.packages.x86_64-linux.nswrap;

    northstarVersion = builtins.head (builtins.match ".*NORTHSTAR_VERSION=([^ ]+).*" (builtins.replaceStrings ["\n"] [" "] (builtins.readFile ./northstar_version.sh)));
    northstarSha256sum = builtins.head (builtins.match ".*NORTHSTAR_GITHUB_SHA256SUM=([^ ]+).*" (builtins.replaceStrings ["\n"] [" "] (builtins.readFile ./northstar_version.sh)));

    northstar = pkgs.stdenv.mkDerivation {
      name = "northstar-${northstarVersion}";

      src = pkgs.fetchurl {
        url = "https://github.com/R2Northstar/Northstar/releases/download/${northstarVersion}/Northstar.release.${northstarVersion}.zip";
        sha256 = "${northstarSha256sum}";
      };

      nativeBuildInputs = [ pkgs.unzip ];
      unpackPhase = "unzip $src -d $out";
    };

    entrypoint = pkgs.runCommand "entrypoint.sh" {} ''
      cp ${./entrypoint.sh} $out
      chmod +x $out
      substituteInPlace $out \
        --replace '/home/northstar/nswine/bin' '${nswine}/bin' \
        --replace '/home/northstar/nswrap/bin/nswrap' '${nswrap}/bin/nswrap'
    '';

  in {
    packages.x86_64-linux.default = pkgs.dockerTools.buildLayeredImage {
      name = "ghcr.io/asillyneko/northstar-dedicated";
      tag = "latest";

      # 26.04
      fromImage = pkgs.dockerTools.pullImage {
        imageName = "ubuntu";
        imageDigest = "sha256:5e275723f82c67e387ba9e3c24baa0abdcb268917f276a0561c97bef9450d0b4";
        sha256 = "sha256-F8kj/q43tlhTi62P803ZsWKZuh2UHwWRlr2phQQQWVQ=";
      };

      contents = [ pkgs.bashInteractive nswine nswrap ];

      extraCommands = ''
        mkdir -p home/northstar mnt/northstar
        cp -r ${northstar}/* mnt/northstar/
      '';

      config = {
        Env = [ "WINEPREFIX=/home/northstar/.wine" "NSWRAP_EXTWINE=1" ];
        WorkingDir = "/home/northstar";
        Entrypoint = [ "${entrypoint}" ];
      };
    };
  };
}
