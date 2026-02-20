{
  stdenv,
  fetchFromGitHub,
  glibc,
  libunwind,
  libgnurl,
  applyPatches,
  doNotPatch ? false,
}:
stdenv.mkDerivation {
  pname = "nswrap";
  version = "1.0.0";

  src = applyPatches {
    src = ../../pg9182-nsdockerwine2;
    patches =
      if doNotPatch then
        [ ]
      else
        [
          ./nswrap.patch
        ];
  };

  nativeBuildInputs = [
  ];
  buildInputs = [
    glibc
    libunwind
    libgnurl
  ];

  buildPhase = ''
    mkdir -p $out/bin/
    gcc -Wall -Wextra $src/nswrap/nswrap.c -o $out/bin/nswrap
  '';

  meta = {
    mainProgram = "nswrap";
  };
}
