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

  cargoHash = "sha256-ryK1NeDZa6635rcilN2+KvdlkzUsVNV9fufIXByoTX0=";

  checkFlags = [
    # Admin ports can't be opened during the build
    "--skip=scanner::tests::test_scanner_1000_empty"
    "--skip=scanner::tests::test_scanner_1000_80_443"
    "--skip=scanner::tests::test_scanner_all_80"
    "--skip=scanner::tests::test_scanner_port_80"
    "--skip=terminal::print::tests::test_terminal_monochrome_false"
  ];

  meta = with lib; {
    description = "A fast configurable port scanner with reasonable defaults";
    homepage = "https://github.com/mrjackwills/${pname}";
    changelog = "https://github.com/mrjackwills/${pname}/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
    mainProgram = pname;
  };
}
