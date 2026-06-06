{
  lib,
  rustPlatform,
  fetchFromGitea,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "croft";
  version = "0-unstable-2026-06-06";
  __structuredAttrs = true;

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "vitali87";
    repo = "croft";
    rev = "5a754708e38a7e4baff594ea29dff0c7c6bc8ff7";
    hash = "sha256-NGAzlCQO2STLtYciCbD5iSH+06cL51ajrgGmzlzt5AU=";
  };

  cargoHash = "sha256-gnIi25MO22JnuGoaK9e2XcSamy/t1iDcYvdcr2yYgRo=";

  # The test suite references a macOS-only clipboard module, so it fails to
  # compile on Linux.
  doCheck = false;

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "VSCode-style TUI written in Rust";
    homepage = "https://codeberg.org/vitali87/croft";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "croft";
  };
})
