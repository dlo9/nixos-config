{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  sqlite,
  stdenv,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "rainfrog";
  version = "0.1.16";

  src = fetchFromGitHub {
    owner = "achristmascarl";
    repo = "rainfrog";
    rev = "v${version}";
    hash = "sha256-kMR620Ux5t6vzgYInYt7wZ2DocmvqmopEJoKj93HA2I=";
  };

  cargoHash = "sha256-J4y4KuAYGAZchHdYx7E4VSPI4M53nV64VSljkXG3UNk=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs =
    [
      sqlite
    ]
    ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.AppKit
      darwin.apple_sdk.frameworks.CoreFoundation
      darwin.apple_sdk.frameworks.CoreGraphics
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
    ];

  meta = with lib; {
    description = "A database management tui for postgres";
    homepage = "https://github.com/achristmascarl/rainfrog";
    license = licenses.mit;
    maintainers = with maintainers; [];
    mainProgram = "rainfrog";
  };
}
