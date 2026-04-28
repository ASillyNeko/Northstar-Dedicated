{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
