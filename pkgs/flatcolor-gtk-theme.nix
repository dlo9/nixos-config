{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "flatcolor-gtk-theme";
  version = "2022-05-28";

  src = fetchFromGitHub {
    owner = "jasperro";
    repo = "FlatColor";
    rev = "0a56c50e8c5e2ad35f6174c19a00e01b30874074";
    sha256 = "0pv3fmvs8bfkn5fwyg9z8fszknmca4sjs3210k15lrrx75hngi1z";
  };

  installPhase = ''
    rm .gitignore README.md
    sed -i 's/Polar Night/FlatColor/' index.theme

    mkdir -p $out/share/themes
    cp -r . $out/share/themes/FlatColor

    runHook postInstall
  '';

  meta = with lib; {
    description = "A simple gtk3 theme based on FlatColor by deviantfero";
    homepage = "https://github.com/jasperro/FlatColor";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    # maintainers = [ dlo9 ];
  };
}
