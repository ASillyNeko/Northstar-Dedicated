{
  stdenvNoCC,
  nswine,
  lib,
  xvfb-run,
}:
let
  wine-ns = nswine;
  wine-name = "wine";
in
stdenvNoCC.mkDerivation {
  pname = "nswine-env";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    nswine
  ];
  buildInputs = [
  ];

  phases = [ "buildPhase" ];
  buildPhase = "
      export XDG_CACHE_HOME=\"\$(mktemp -d)\"      

      export WINEARCH=win64 WINEDLLOVERRIDES=\"mscoree,mshtml,winemenubuilder.exe=\"
      export WINEPREFIX=$out/wine
      mkdir -p $out/wine
      mkdir -p $out/bin/
      
      ${lib.getExe' nswine wine-name} wineboot --init
      ${lib.getExe' nswine wine-name} reg add 'HKCU\\Software\\Wine' /v 'Version' /t REG_SZ /d 'win10' /f
      ${lib.getExe' nswine wine-name} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Audio' /t REG_SZ /d '' /f
      ${lib.getExe' nswine wine-name} reg add 'HKCU\\Software\\Wine\\WineDbg' /v 'ShowCrashDialog' /t REG_DWORD /d 0 /f
      ${lib.getExe' nswine wine-name} reg add 'HKCU\\Software\\Wine\\Drivers' /v 'Graphics' /t REG_SZ /d 'null' /f
      ${lib.getExe' nswine wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mscoree' /t REG_SZ /d '' /f
      ${lib.getExe' nswine wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'mshtml' /t REG_SZ /d '' /f
      ${lib.getExe' nswine wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'winemenubuilder' /t REG_SZ /d '' /f
      ${lib.getExe' nswine wine-name} reg add 'HKCU\\Software\\Wine\\DllOverrides' /v 'd3d11' /t REG_SZ /d 'native' /f
      ${lib.getExe' nswine wine-name} wineboot --shutdown --force
      ${lib.getExe' nswine wine-name} wineboot --kill --force
  ";
}
