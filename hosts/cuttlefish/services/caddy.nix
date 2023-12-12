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

  autheliaForwardAuth = ''
    forward_auth http://192.168.1.230:1080 {
      transport http {
        proxy_protocol v2
      }

      header_up Host "auth.sigpanic.com"
      uri /api/verify?rd=https://auth.sigpanic.com
      copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }
  '';

  # TODO: Make the available outside this file, so that configs can be adjacent to their services
  authentikForwardAuth = ''
    # forward authentication to outpost
    forward_auth http://192.168.1.230:1080 {
        header_up Host "authentik.sigpanic.com"
        uri /outpost.goauthentik.io/auth/caddy

        copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider X-Authentik-Meta-App X-Authentik-Meta-Version Remote-User Remote-Groups Remote-Name Remote-Email
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

    # Actual caddy definition
    services.caddy = {
      enable = true;

      # Add modules via:
      # https://github.com/NixOS/nixpkgs/issues/14671#issuecomment-1253111596
      # https://github.com/caddyserver/caddy/blob/master/cmd/caddy/main.go
      package = pkgs.dlo9.caddy;

      virtualHosts = {
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

        sunshine = {
          inherit useACMEHost;
          serverAliases = ["sunshine.sigpanic.com"];
          extraConfig = ''
            ${autheliaForwardAuth}

            reverse_proxy https://winvm.lan:47990 {
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

        netdata = {
          inherit useACMEHost;
          serverAliases = ["netdata.sigpanic.com"];
          extraConfig = ''
            ${authentikForwardAuth}
            reverse_proxy http://localhost:${config.services.netdata.config.web."default port"}
          '';
        };

        traefik = {
          inherit useACMEHost;
          serverAliases = ["*.sigpanic.com"];
          extraConfig = ''
            reverse_proxy http://192.168.1.230:1080 {
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

        # http_port 81
        # https_port 444

        http_port 80
        https_port 443
      '';
    };
  };
}
