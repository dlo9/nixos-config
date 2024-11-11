{
  lib,
  buildGo123Module,
  fetchFromGitHub,
}:
buildGo123Module rec {
  pname = "cy";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "cfoust";
    repo = "cy";
    rev = "v${version}";
    hash = "sha256-05yld6cU0P+0u9BvZ873APATN74AmwT6Uu1/GVL9y9U=";
  };

  vendorHash = null;
  doCheck = false;

  ldflags = ["-s" "-w"];

  meta = with lib; {
    description = "Time travel in the terminal";
    homepage = "https://github.com/cfoust/cy";
    license = licenses.mit;
    maintainers = with maintainers; [];
    mainProgram = "cy";
  };
}
