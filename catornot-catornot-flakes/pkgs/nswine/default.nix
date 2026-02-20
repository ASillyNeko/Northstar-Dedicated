{
  stdenvNoCC,
  wine64Packages,
  fetchFromGitHub,
  buildGoModule,
  unixtools,
  hexdump,
  writers,
  lib,
}:
let
  wine-ns = wine64Packages.stable;
  nswine = buildGoModule {
    pname = "nswine";
    version = "1.0.0";
    src = ../../pg9182-nsdockerwine2/nswine;

    vendorHash = "sha256-8B1nbk0ZaYEuujSsdF+KgXFimQdj8JAujQj0af6ECfM=";
  };
  patchthething =
    writers.writeRustBin "nswine-run" { } # rust
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
    hexdump
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

      mkdir -p $TMP/wine
      mkdir -p $TMP/lib/wine/x86_64-windows

      NSWINE_UNSAFE=1 nswine --prefix $out --output $TMP/wine -debug -optimize

      ${lib.getExe patchthething} $out/lib/wine/x86_64-windows/explorer.exe

      xxd ${wine-ns}/lib/wine/x86_64-windows/explorer.exe > $TMP/diff1
      xxd $out/lib/wine/x86_64-windows/explorer.exe > $TMP/diff2

      ! diff $TMP/diff1 $TMP/diff2

      ! diff ${wine-ns}/share/wine/wine.inf $out/share/wine/wine.inf
  ";
}

# makeWrapper $out/bin/wine64 \
#   --suffix PATH : ${
#   lib.makeBinPath [
#     xdg-utils
#     xvfb-run
#   ]
# }
