{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
  useACMEHost = "sigpanic.com";
  listenAddresses = ["0.0.0.0"];
  tailscaleDomain = "fairy-koi.ts.net";

  # TODO: figure out why https doesn't work here
  auth = ''
    forward_auth http://10.1.0.1:1080 {
        header_up Host "authelia.sigpanic.com"
        uri /api/authz/forward-auth

        copy_headers Remote-User Remote-Name Remote-Email Remote-Groups
    }
  '';
in {
  config = {
    # Give caddy cert access
    users.users.caddy.extraGroups = ["acme"];

    # Reload caddy on new certs
    security.acme.defaults.reloadServices = ["caddy"];

    # Open ports
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    # Secrets
    systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets."caddy-env".path;

    # Kubernetes depends on nexus for container images
    systemd.services.caddy.before = ["kubernetes.slice"];

    # Actual caddy definition
    # Add modules via:
    # https://github.com/NixOS/nixpkgs/issues/14671#issuecomment-1253111596
    # https://github.com/caddyserver/caddy/blob/master/cmd/caddy/main.go
    services.caddy = {
      enable = true;

      package = pkgs.caddy.withPlugins {
        plugins = [
          # https://caddyserver.com/docs/modules/http.handlers.replace_response
          "github.com/caddyserver/replace-response@v0.0.0-20240710174758-f92bc7d0c29d"
        ];

        hash = "sha256-cFjqgD9uzAglDcLZG286qeum/srkCuJWLKCxiqY15nM=";
      };

      virtualHosts = {
        trident = {
          inherit useACMEHost;
          serverAliases = ["trident.sigpanic.com"];
          extraConfig = ''
            ${auth}

            handle_path /stream.html* {
                reverse_proxy http://trident:1984 {
                  header_up -Authorization
                  header_up -X-Forwarded-For
                  header_up -X-Real-IP
                }
            }

            handle {
              reverse_proxy http://trident {
                # Don't pass JWT to fluidd, since it's an authentik token and not moonraker token
                # Rely on moonraker's trusted_proxies instead
                header_up -Authorization
                header_up -X-Forwarded-For
                header_up -X-Real-IP
              }
            }
          '';
        };

        beszel = {
          inherit useACMEHost;
          serverAliases = ["beszel.sigpanic.com"];
          extraConfig = ''
            ${auth}
            reverse_proxy http://localhost:8090
          '';
        };

        jellyfin = {
          inherit useACMEHost;
          serverAliases = ["jellyfin.sigpanic.com"];
          extraConfig = ''
            reverse_proxy http://jellyfin.containers:8096
          '';
        };

        webdav = {
          inherit useACMEHost;
          serverAliases = ["webdav.sigpanic.com"];
          extraConfig = ''
            reverse_proxy http://localhost:12345
          '';
        };

        nexus = {
          inherit useACMEHost;
          serverAliases = ["nexus.sigpanic.com"];
          extraConfig = ''
            reverse_proxy http://localhost:${toString config.services.nexus.listenPort}
          '';
        };

        docker = {
          inherit useACMEHost;
          serverAliases = ["docker.sigpanic.com"];
          extraConfig = ''
            # Nexus Container Registry
            reverse_proxy http://localhost:8082
          '';
        };

        nix-serve = {
          inherit useACMEHost;
          serverAliases = ["nix-serve.sigpanic.com"];
          extraConfig = ''
            reverse_proxy http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}
          '';
        };

        sunshine = {
          inherit useACMEHost;
          serverAliases = ["sunshine.sigpanic.com"];
          extraConfig = ''
            ${auth}

            #reverse_proxy https://winvm.lan:47990 {
            reverse_proxy https://localhost:47990 {
              header_up Authorization "Basic {$SUNSHINE_BASIC_AUTH}"
              transport http {
                tls_insecure_skip_verify
              }
            }
          '';
        };

        recipes = {
          inherit useACMEHost;
          serverAliases = ["recipes.sigpanic.com"];
          extraConfig = ''
            redir https://food.sigpanic.com{uri} permanent
          '';
        };

        router = {
          inherit useACMEHost;
          serverAliases = ["router.sigpanic.com"];
          extraConfig = ''
            ${auth}
            reverse_proxy http://192.168.1.1
          '';
        };

        ttyd = {
          inherit useACMEHost;
          serverAliases = ["ttyd.sigpanic.com" "term.sigpanic.com"];
          extraConfig = ''
            ${auth}
            reverse_proxy http://localhost:7681
          '';
        };

        wedding = {
          inherit useACMEHost;
          serverAliases = ["wedding.sigpanic.com"];
          extraConfig = ''
            redir https://withjoy.com/chelsea-and-david-eclt69ttx1000r01ys9dgbfoaks/{uri} permanent
          '';
        };

        netdata = {
          inherit useACMEHost;
          serverAliases = ["netdata.sigpanic.com"];
          extraConfig = ''
            ${auth}
            reverse_proxy http://localhost:${config.services.netdata.config.web."default port"}
          '';
        };

        traefik = {
          inherit useACMEHost;
          serverAliases = ["*.sigpanic.com"];
          extraConfig = ''
            reverse_proxy http://10.1.0.1:1080 {
              transport http {
                proxy_protocol v2
              }
            }
          '';
        };
      };

      logFormat = ''
        level DEBUG
      '';

      globalConfig = ''
        debug
        auto_https disable_certs

        order replace after encode

        http_port 80
        https_port 443
      '';
    };
  };
}
