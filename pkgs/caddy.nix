{ lib
, buildGoModule
, fetchFromGitHub
, nixosTests
, caddy
, testers
, installShellFiles
}:

let
  version = "2.7.0-beta.1";
  dist = fetchFromGitHub {
    owner = "caddyserver";
    repo = "dist";
    rev = "v${version}";
    hash = "sha256-1CjrONP6W1DYsKMezfjf0/JeV1GrrvBYbx93LDUGJvk=";
  };
in

buildGoModule {
  pname = "caddy";
  inherit version;

  src = fetchFromGitHub {
    owner = "caddyserver";
    repo = "caddy";
    rev = "v${version}";
    hash = "sha256-wbAbSw/z0FM2UEhG6gks7Dj3HEXDISF+vcjc5wzYNH8=";
  };

  vendorHash = "sha256-PJi5G7FGSAiZ1WyyrxWYBIMzr8zXn+9EXWtmAPQiE7s=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    install -Dm644 ${dist}/init/caddy.service ${dist}/init/caddy-api.service -t $out/lib/systemd/system

    substituteInPlace $out/lib/systemd/system/caddy.service --replace "/usr/bin/caddy" "$out/bin/caddy"
    substituteInPlace $out/lib/systemd/system/caddy-api.service --replace "/usr/bin/caddy" "$out/bin/caddy"

    $out/bin/caddy manpage --directory manpages
    installManPage manpages/*

    installShellCompletion --cmd metal \
      --bash <($out/bin/caddy completion bash) \
      --fish <($out/bin/caddy completion fish) \
      --zsh <($out/bin/caddy completion zsh)
  '';

  passthru.tests = {
    inherit (nixosTests) caddy;
    version = testers.testVersion {
      command = "${caddy}/bin/caddy version";
      package = caddy;
    };
  };

  meta = with lib; {
    homepage = "https://caddyserver.com";
    description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
    license = licenses.asl20;
    maintainers = with maintainers; [ Br1ght0ne indeednotjames techknowlogick ];
  };
}
