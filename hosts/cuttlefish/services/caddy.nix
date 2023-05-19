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
      80
      443
    ];

    # Actual caddy definition
    services.caddy = {
      enable = true;

      # Add modules via:
      # https://github.com/NixOS/nixpkgs/issues/14671#issuecomment-1253111596
      # https://github.com/caddyserver/caddy/blob/master/cmd/caddy/main.go
      package = config.sys.pkgs.caddy;

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

          traefik = {
            inherit useACMEHost;
            serverAliases = [ "*.sigpanic.com" ];
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
