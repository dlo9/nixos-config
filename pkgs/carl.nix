{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "carl";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "b1rger";
    repo = "carl";
    rev = "v${version}";
    hash = "sha256-+l11eP+1qKrWbZhyUJgQ8FgQ+2rncx778F5RPzCfvV4=";
  };

  cargoHash = "sha256-nBl34szwEQX26MibfT10E55czYXN3/9W3y2z936KqTc=";

  # Found argument '--test-threads' which wasn't expected, or isn't valid in this context
  doCheck = false;

  meta = with lib; {
    description = "Carl is a calendar for the commandline. It tries to mimic the various cal(1) implementations out there, but also adds enhanced features like colors and ical support";
    homepage = "https://github.com/b1rger/carl";
    changelog = "https://github.com/b1rger/carl/blob/${src.rev}/CHANGELOG.md";
    license = licenses.unfree; # FIXME: nix-init did not found a license
    maintainers = with maintainers; [];
    mainProgram = "carl";
  };
}
