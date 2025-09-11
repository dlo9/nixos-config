{
  lib,
  rustPlatform,
  fetchFromGitHub,
  libpcap,
}:
rustPlatform.buildRustPackage rec {
  pname = "rustnet";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "domcyrus";
    repo = "rustnet";
    rev = "v${version}";
    hash = "sha256-kW0dea9gr9ZYOTGr8jn3qOX6lVo7mAYvTzL32RNEUns=";
  };

  cargoHash = "sha256-mLdhoL7+RMe6pY65jI38xegb8ZZL1NUzeI+88s+owbo=";

  buildInputs = [
    libpcap
  ];

  meta = {
    description = "A cross-platform network monitoring terminal UI tool built with Rust";
    homepage = "https://github.com/domcyrus/rustnet";
    changelog = "https://github.com/domcyrus/rustnet/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [];
    mainProgram = "rustnet";
  };
}
