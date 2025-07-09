{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "somo";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "theopfr";
    repo = "somo";
    rev = "v${version}";
    hash = "sha256-HUTaBSy3FemAQH1aKZYTJnUWiq0bU/H6c5Gz3yamPiA=";
  };

  cargoHash = "sha256-e3NrEfbWz6h9q4TJnn8jnRmMJbeaEc4Yo3hFlaRLzzQ=";

  nativeBuildInputs = [
    rustPlatform.bindgenHook
  ];

  meta = {
    description = "A human-friendly alternative to netstat for socket and port monitoring on Linux";
    homepage = "https://github.com/theopfr/somo";
    changelog = "https://github.com/theopfr/somo/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "somo";
  };
}
