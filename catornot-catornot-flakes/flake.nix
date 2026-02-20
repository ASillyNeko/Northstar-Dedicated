{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
  };

  outputs =
    {
      self,
      ...
    }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./pkgs
        (
          { withSystem, ... }:
          {
            flake.overlays.northstar =
              final: prev:
              withSystem prev.stdenv.hostPlatform.system (
                { config, ... }:
                {
                  nswine-env = config.packages.nswine-env;
                  nswrap = config.packages.nswrap;
                  nswine = config.packages.nswine;
                }
              );
          }
        )
      ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
        };
    };
}
