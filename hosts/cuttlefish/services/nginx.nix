{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  useACMEHost = "sigpanic.com";
  sysCfg = config.sys;
in
{
  config = {
    # Give nginx cert access
    users.users.nginx.extraGroups = [ "acme" ];

    # Reload nginx on new certs
    security.acme.defaults.reloadServices = [ "nginx" ];

    # Open ports
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    # Actual nginx definition
    services.nginx = {
      enable = true;

      enableReload = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      appendHttpConfig = ''
        # upstream sent too big header while reading response header from upstream
        proxy_busy_buffers_size   512k;
        proxy_buffers   4 512k;
        proxy_buffer_size   256k;
      '';

      # Necessary for photo uploads, backups, etc.
      clientMaxBodySize = "50M";

      virtualHosts = {
        "webdav.${useACMEHost}" = {
          inherit useACMEHost;
          forceSSL = true;

          locations."/" = {
            proxyPass = "http://localhost:12345";
            proxyWebsockets = true;
          };
        };

        "router.${useACMEHost}" = {
          inherit useACMEHost;
          forceSSL = true;

          locations."/" = {
            proxyPass = "http://192.168.1.1";
            proxyWebsockets = true;
          };
        };

        "*.${useACMEHost}" = {
          inherit useACMEHost;
          forceSSL = true;
          default = true;

          locations."/" = {
            proxyPass = "http://192.168.1.230:1080";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
