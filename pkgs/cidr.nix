{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "cidr";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "bschaatsbergen";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-cYEXKkE0NWJ5HBhVUWuKB5tdDdgprDly1HjhVPUPAww=";
  };

  vendorHash = "sha256-Of83mANA8yKQFa8bIi5l8FR7NHA7bGrDPTtyc0PAsg4=";

  meta = with lib; {
    description = "CLI to perform various actions on CIDR ranges";
    homepage = "https://github.com/bschaatsbergen/${pname}";
    license = licenses.mit;
    mainProgram = pname;
  };
}
