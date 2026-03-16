{
  stdenvNoCC,
  wine64Packages,
  buildGoModule,
  unixtools,
  writers,
  lib,
  removeReferencesTo,
}:
let
  wine-ns = wine64Packages.minimal;
  wine-stable = wine64Packages.stable;
  nswine = buildGoModule {
    pname = "nswine";
    version = "1.0.0";
    src = ../../pg9182-nsdockerwine2/nswine;

    vendorHash = "sha256-RFOeqr9hvj/WWY19solDAMhajzqtQ82+2SDw5ce6zhI=";
  };
  patchthething =
    writers.writeRustBin "patchthething" { } # rust
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
stdenvNoCC.mkDerivation {
  pname = "nswine";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    nswine
    unixtools.xxd
    removeReferencesTo
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

      # update these by running this and copying bcrypt.dll and bcrypt.so into wine directory
      # nix build --impure --expr 'let pkgs = import <nixpkgs> {}; in pkgs.wine64Packages.minimal.override { tlsSupport = true; }'
      cp $src/wine/bcrypt.dll $out/lib/wine/x86_64-windows/bcrypt.dll
      cp $src/wine/bcrypt.so $out/lib/wine/x86_64-unix/bcrypt.so

      mkdir -p $TMP/wine
      mkdir -p $TMP/lib/wine/x86_64-windows

      NSWINE_UNSAFE=1 nswine --prefix $out --output $TMP/wine -debug -optimize

      ${lib.getExe patchthething} $out/lib/wine/x86_64-windows/explorer.exe

      ! diff ${wine-ns}/share/wine/wine.inf $out/share/wine/wine.inf

      find $out -type f | xargs -r remove-references-to -t ${wine-ns} -t ${wine-stable}
  ";
}
