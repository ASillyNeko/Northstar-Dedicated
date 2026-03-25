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

      fromImage = pkgs.dockerTools.pullImage {
        imageName = "ubuntu";
        imageDigest = "sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c";
        sha256 = "sha256-Wpf0yKdEWJIWrURX+uyLZnqjJ95IO99subetxl6krY0=";
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
