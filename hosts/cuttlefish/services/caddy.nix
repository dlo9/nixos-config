{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  useACMEHost = "sigpanic.com";
  listenAddresses = [ "0.0.0.0" ];
  sysCfg = config.sys;
  simpleProxy = (name: value: {
    "${name}" = {
      useACMEHost = "sigpanic.com";
      serverAliases = [ "${name}.sigpanic.com" ];
      extraConfig = ''
        reverse_proxy http://${name}.containers:8096
      '';
    };
  });
in
{
  options.reverseProxies = mkOption {
    type = types.attrsOf types.nonEmptyStr;
    # default = [];
    description = "Hostname to upstream proxy config";
  };

  config = {
    # Give caddy cert access
    users.users.caddy.extraGroups = [ "acme" ];

    # Reload caddy on new certs
    security.acme.defaults.reloadServices = [ "caddy" ];

    # Open ports
    networking.firewall.allowedTCPPorts = [
      #81
      #444

      80
      443
    ];

    # Actual caddy definition
    services.caddy = {
      enable = true;

      # https://github.com/NixOS/nixpkgs/issues/14671#issuecomment-1253111596
      # https://github.com/caddyserver/caddy/blob/master/cmd/caddy/main.go
      package = with pkgs;
        let
          version = "2.6.4";

          dist = fetchFromGitHub {
            owner = "caddyserver";
            repo = "dist";
            rev = "v${version}";
            hash = "sha256-SJO1q4g9uyyky9ZYSiqXJgNIvyxT5RjrpYd20YDx8ec=";
          };

          caddySrc = srcOnly (fetchFromGitHub {
            owner = "caddyserver";
            repo = "caddy";
            rev = "v${version}";
            hash = "sha256-3a3+nFHmGONvL/TyQRqgJtrSDIn0zdGy9YwhZP17mU0=";
          });

          pluginSrc = srcOnly (fetchFromGitHub {
            owner = "greenpau";
            repo = "caddy-security";
            rev = "v1.1.18";
            hash = "sha256-Ae3tycq0gdo0ySU3CSDau+pNkNGsN0PqOkm7IFxmXGI=";
          });

          main = writeTextFile
            {
              name = "main.go";
              text = ''
                package main

                import (
                  caddycmd "github.com/caddyserver/caddy/v2/cmd"

                  // plug in Caddy modules here
                  _ "github.com/caddyserver/caddy/v2/modules/standard"
                  _ "github.com/greenpau/caddy-security"
                )

                func main() {
                  caddycmd.Main()
                }
              '';
            };

          combinedSrc = stdenv.mkDerivation {
            name = "caddy-src";

            nativeBuildInputs = [ go ];

            buildCommand = ''
              export GOCACHE="$TMPDIR/go-cache"
              export GOPATH="$TMPDIR/go"

              # Create directory for "main" go module
              mkdir -p "$out/caddybin"
              cd "$out/caddybin"

              # Vendor caddy and plugin sources
              cp -r ${caddySrc} "../caddy"
              cp -r ${pluginSrc} "../plugin"

              # Create the go module
              go mod init caddy

              cp ${main} main.go

              # Replace go.mod dependencies with our vendored versions
              go mod edit -require=github.com/caddyserver/caddy/v2@v2.6.2
              go mod edit -replace github.com/caddyserver/caddy/v2=../caddy
              go mod edit -require=github.com/greenpau/caddy-security@v1.1.18
              go mod edit -replace github.com/greenpau/caddy-security=../plugin
            '';
          };
        in
        buildGoModule {
          name = "caddy";
          src = combinedSrc;
          vendorHash = "sha256-bfAIvr4Xnnm7ebU5LzbTfAxK4s3LBE7OAloDDk965bo=";

          overrideModAttrs = _: {
            postPatch = "cd caddybin";

            postConfigure = ''
              go mod tidy
            '';

            postInstall = ''
              mkdir -p "$out/.magic"
              cp go.mod go.sum "$out/.magic"
            '';
          };

          postPatch = "cd caddybin";

          postConfigure = ''
            cp vendor/.magic/go.* .
          '';

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
        };

      virtualHosts =
        (mapAttrs simpleProxy config.reverseProxies) // {
          keycloak = {
            inherit useACMEHost;
            serverAliases = [ "keycloak.sigpanic.com" ];
            extraConfig = ''
              reverse_proxy http://keycloak.containers

              # header {
              #   X-Frame-Options SAMEORIGIN
              # }
            '';
          };

          jellyfin = {
            inherit useACMEHost;
            serverAliases = [ "jellyfin.sigpanic.com" ];
            extraConfig = ''
              reverse_proxy http://jellyfin.containers:8096
            '';
          };

          webdav = {
            inherit useACMEHost;
            serverAliases = [ "webdav.sigpanic.com" ];
            extraConfig = ''
              reverse_proxy http://localhost:12345
            '';
          };

          # router = {
          #   inherit useACMEHost;
          #   serverAliases = [ "router.sigpanic.com" ];
          #   extraConfig = ''
          #     forward_auth http://keycloak.containers {
          #       uri /api/verify?rd=https://auth.example.com
          #       copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
          #     }

          #     reverse_proxy http://192.168.1.1
          #   '';
          # };

          traefik = {
            inherit useACMEHost;
            serverAliases = [ "*.sigpanic.com" ];
            extraConfig = ''
              reverse_proxy http://192.168.1.230:1080
            '';
          };
        };

      logFormat = ''
        level DEBUG
      '';

      globalConfig = ''
        debug
        auto_https disable_certs

        # http_port 81
        # https_port 444

        http_port 80
        https_port 443
      '';
    };
  };
}
