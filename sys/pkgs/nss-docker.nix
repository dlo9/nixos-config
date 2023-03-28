{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "nss-docker";
  version = "0.02";

  src = fetchFromGitHub {
    owner = "dex4er";
    repo = "nss-docker";
    rev = "${version}";
    sha256 = "sha256-fFC+BkmcuIZCFUMC2HFdnXUsI69+qZCCz8DqFWjuIUo=";
  };

  meta = with lib; {
    description = "NSS module for finding Docker containers";
    homepage = "https://github.com/dex4er/nss-docker";
    license = licenses.lgpl21Only;
    platforms = platforms.linux;
  };
}
