{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
  useACMEHost = "drywell.sigpanic.com";

  authentikForwardAuth = ''
    # forward authentication to outpost
    forward_auth https://authentik.sigpanic.com {
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

    # Actual caddy definition
    services.caddy = {
      enable = true;

      # Add modules via:
      # https://github.com/NixOS/nixpkgs/issues/14671#issuecomment-1253111596
      # https://github.com/caddyserver/caddy/blob/master/cmd/caddy/main.go
      package = pkgs.dlo9.caddy;

      virtualHosts = {
        router = {
          inherit useACMEHost;
          serverAliases = ["router.${useACMEHost}"];
          extraConfig = ''
            ${authentikForwardAuth}
            reverse_proxy http://192.168.1.1
          '';
        };

        webdav = {
          inherit useACMEHost;
          serverAliases = ["webdav.${useACMEHost}"];
          extraConfig = ''
            reverse_proxy http://localhost:12345
          '';
        };
      };

      logFormat = ''
        level DEBUG
      '';

      globalConfig = ''
        debug
        auto_https disable_certs

        http_port 80
        https_port 443
      '';
    };
  };
}
