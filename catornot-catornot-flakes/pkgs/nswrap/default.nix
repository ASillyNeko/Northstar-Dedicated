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
    src = fetchFromGitHub {
      owner = "pg9182";
      repo = "nsdockerwine2";
      rev = "c412fb15ef20ebb6ba674796ac527a558942772a";
      sha256 = "sha256-Y0oDQYUnsChdRyId73paTTgJ2k5n0Y3Cn1Y2TeHdwDo=";
    };
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
