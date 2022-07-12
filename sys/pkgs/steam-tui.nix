{ lib
, rustPlatform
, steamcmd
, openssl
, pkgconfig
, fetchFromGitHub
, steam-run
, runtimeShell
, withWine ? false
, wine
}:

rustPlatform.buildRustPackage rec {
  pname = "steam-tui";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "dmadisetti";
    repo = pname;
    rev = version;
    sha256 = "13aqpjadc0wmgyk2wi6aidrm8msfdfpm3bzvyj2c0i5giyviinv5";
  };

  cargoHash = "sha256-oeyPHFORdo0wsmdM2gdv1sNGX9lFPmbVwPE6fOtUkS4=";

  nativeBuildInputs = [
    openssl
    pkgconfig
  ];

  packages = [
    steamcmd
  ];

  PKG_CONFIG_PATH = "${openssl.dev}/lib/pkgconfig";
  doCheck = false;

  buildInputs = [ steamcmd ]
    ++ lib.optional withWine wine;

  preFixup = ''
    mv $out/bin/steam-tui $out/bin/.steam-tui-unwrapped
    cat > $out/bin/steam-tui <<EOF
    #!${runtimeShell}
    export PATH=${steamcmd}/bin:\$PATH
    exec ${steam-run}/bin/steam-run $out/bin/.steam-tui-unwrapped '\$@'
    EOF
    chmod +x $out/bin/steam-tui
  '';

  meta = with lib; {
    description = "Rust TUI client for steamcmd";
    homepage = "https://github.com/dmadisetti/steam-tui";
    license = licenses.mit;
    maintainers = with maintainers; [ lom ];
    # steam only supports that platform
    platforms = [ "x86_64-linux" ];
  };
}
