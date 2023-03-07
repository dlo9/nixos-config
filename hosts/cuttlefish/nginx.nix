{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  useACMEHost = "sigpanic.com";
  sysCfg = config.sys;
in
{
  config = {
    sops.secrets.cloudflare-dns = {
      sopsFile = sysCfg.secrets.hostSecretsFile;
    };

    security.acme = {
      acceptTerms = true;

      defaults = {
        # Testing environment
        #server = "https://acme-staging-v02.api.letsencrypt.org/directory";

        email = "if_coding@fastmail.com";
        dnsProvider = "cloudflare";
        credentialsFile = config.sops.secrets.cloudflare-dns.path;
      };

      certs."${useACMEHost}" = {
        #ocspMustStaple = true;
        group = "nginx";
        extraDomainNames = [
          "*.sigpanic.com"
        ];
      };
    };

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

    networking.firewall.interfaces.lan.allowedTCPPorts = [
      80
      443
    ];
  };
}
