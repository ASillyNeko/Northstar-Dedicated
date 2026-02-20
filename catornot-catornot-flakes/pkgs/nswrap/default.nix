{
  stdenv,
}:
stdenv.mkDerivation {
  pname = "nswrap";
  version = "1.0.0";

  src = ../../pg9182-nsdockerwine2;

  nativeBuildInputs = [
  ];
  buildInputs = [
  ];

  buildPhase = ''
    mkdir -p $out/bin/
    gcc -Wall -Wextra $src/nswrap/nswrap.c -o $out/bin/nswrap
  '';

  meta = {
    mainProgram = "nswrap";
  };
}
