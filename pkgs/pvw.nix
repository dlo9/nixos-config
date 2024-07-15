{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "pvw";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "allyring";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-rjiIMiPSdZgiFEqqHjw+QRNeWhgBcMqcfDgkEP22VyE=";
  };

  vendorHash = "sha256-5xOLFZM+OdzS7wM7+Hp508WLEOP6wLD5EZ+NS8FNb0c=";

  meta = with lib; {
    description = "A port viewer TUI for Unix made with BubbleTea in Go";
    homepage = "https://github.com/allyring/${pname}";
    license = licenses.gpl3Only;
    mainProgram = pname;
  };
}
