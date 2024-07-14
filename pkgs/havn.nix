{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "havn";
  version = "0.1.12";

  src = fetchFromGitHub {
    owner = "mrjackwills";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-BCg572435CdQMOldm3Ao4D+sDxbXUlDxMWmxa+aqTY0=";
  };

  cargoHash = "sha256-JaAlWiaOUoXSV6O4wmU7zCR5h5olO2zkB5WEGk2/ZdE=";

  checkFlags = [
    # Admin ports can't be opened during the build
    "--skip=scanner::tests::test_scanner_1000_80_443"
    "--skip=scanner::tests::test_scanner_all_80"
    "--skip=scanner::tests::test_scanner_port_80"
    "--skip=terminal::print::tests::test_terminal_monochrome_false"
  ];

  meta = with lib; {
    description = "A fast configurable port scanner with reasonable defaults";
    homepage = "https://github.com/mrjackwills/havn";
    changelog = "https://github.com/mrjackwills/havn/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
    mainProgram = pname;
  };
}
