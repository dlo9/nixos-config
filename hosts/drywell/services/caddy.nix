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

  auth = ''
    forward_auth https://authelia.sigpanic.com {
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

    # Actual caddy definition
    # Add modules via:
    # https://github.com/NixOS/nixpkgs/issues/14671#issuecomment-1253111596
    # https://github.com/caddyserver/caddy/blob/master/cmd/caddy/main.go
    services.caddy = {
      enable = true;

      virtualHosts = {
        immich = {
          inherit useACMEHost;

          serverAliases = [
            "immich.${useACMEHost}"
            "photos.${useACMEHost}"
          ];

          extraConfig = ''
            reverse_proxy http://localhost:3001
          '';
        };
        router = {
          inherit useACMEHost;
          serverAliases = ["router.${useACMEHost}"];
          extraConfig = ''
            ${auth}
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
