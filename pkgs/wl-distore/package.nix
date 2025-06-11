{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  stdenv,
  wayland,
}:

rustPlatform.buildRustPackage rec {
  pname = "wl-distore";
  version = "unstable-2024-11-16";

  src = fetchFromGitHub {
    owner = "andriyDev";
    repo = "wl-distore";
    rev = "367cc6f7c527fff0e1029eabafb70cd25efed961";
    hash = "sha256-mcMfVPNDWU9jRZgRJKcWmiYpctlx7Kg/pOiO64dUEgE=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = lib.optionals stdenv.isLinux [
    wayland
  ];

  meta = {
    description = "A Wayland output configuration watcher for wlroots";
    homepage = "https://github.com/andriyDev/wl-distore";
    license = with lib.licenses; [ asl20 mit ];
    maintainers = with lib.maintainers; [ ];
    mainProgram = "wl-distore";
  };
}
