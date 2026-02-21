{
  inputs,
  self,
  ...
}:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    {
      system,
      pkgs,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
      };

      packages =
        let
          pkgs-win = import inputs.nixpkgs {
            inherit system;
            crossSystem = {
              config = "x86_64-w64-mingw32";
              libc = "msvcrt";
            };
            config.microsoftVisualStudioLicenseAccepted = true;
            config.allowUnfree = true;
            config.allowUnsupportedSystem = true;
          };
        in
        rec {
          nswrap = pkgs.callPackage ./nswrap { };
          nswine-env = pkgs.callPackage ./nswine-env { inherit nswine; };
          nswine = pkgs.callPackage ./nswine { };
        };
    };
}
