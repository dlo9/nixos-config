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
