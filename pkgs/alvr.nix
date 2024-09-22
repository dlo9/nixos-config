{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  bzip2,
  libxkbcommon,
  openssl,
  pipewire,
  vulkan-loader,
  zstd,
  stdenv,
  darwin,
  alsa-lib,
  wayland,
  jack2,
  libva,
  fetchzip,
  autoPatchelfHook,
  brotli,
  ffmpeg,
  libdrm,
  libGL,
  libunwind,
  libvdpau,
  nix-update-script,
  SDL2,
  x264,
  xorg,
  xvidcore,
}:
rustPlatform.buildRustPackage rec {
  pname = "alvr";
  version = "20.10.0";

  src = fetchFromGitHub {
    owner = "alvr-org";
    repo = "alvr";
    rev = "v${version}";
    hash = "sha256-2d5+9rxCpqgLMab7i1pLKaY1qSKRxzPI7pgh54rQBdg=";
    fetchSubmodules = true;
  };

  cargoLock = {
    lockFile = ./alvr.Cargo.lock;
    outputHashes = {
      "openxr-0.17.1" = "sha256-fG/JEqQQwKP5aerANAt5OeYYDZxcvUKCCaVdWRqHBPU=";
      "settings-schema-0.2.0" = "sha256-luEdAKDTq76dMeo5kA+QDTHpRMFUg3n0qvyQ7DkId0k=";
    };
  };

  # patches = [
  #   ./alvr.intel.patch
  # ];

  nativeBuildInputs = [
    autoPatchelfHook
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    alsa-lib
    libunwind
    libva
    libvdpau
    vulkan-loader
    SDL2
    pipewire
    jack2
    openssl
    zstd
    ffmpeg

    xorg.libX11
    xorg.libXcursor
    xorg.libxcb
    xorg.libXi
    xorg.xrandr
  ];

  runtimeDependencies = [
    brotli
    ffmpeg
    openssl
    libdrm
    libGL
    libxkbcommon
    wayland
    x264
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = with lib; {
    description = "Stream VR games from your PC to your headset via Wi-Fi";
    homepage = "https://github.com/alvr-org/alvr";
    changelog = "https://github.com/alvr-org/alvr/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [];
    mainProgram = "alvr";
  };
}
