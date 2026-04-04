{
  lib,
  stdenvNoCC,
  fetchgit,
  kdePackages,
}:
stdenvNoCC.mkDerivation {
  pname = "fluid-tile";
  version = "7.2";

  src = fetchgit {
    url = "https://codeberg.org/Serroda/fluid-tile.git";
    rev = "v7.2";
    hash = "sha256-OgaixENd6Y+7z8UWxkLXAFmEWQolzZ3LvzrX/3MsXj8=";
  };

  nativeBuildInputs = with kdePackages; [
    kpackage
    kwin
  ];

  dontBuild = true;
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall
    kpackagetool6 --type=KWin/Script --install=. --packageroot=$out/share/kwin/scripts
    runHook postInstall
  '';

  meta = {
    description = "Auto tiling for KDE Plasma 6";
    homepage = "https://codeberg.org/Serroda/fluid-tile";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
}
