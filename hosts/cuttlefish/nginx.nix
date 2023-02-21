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
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts = {
        "webdav.${useACMEHost}" = {
          inherit useACMEHost;
          forceSSL = true;

          locations."/" = {
            proxyPass = "http://localhost:12345";
            proxyWebsockets = true;
            extraConfig = ''
              client_max_body_size 50M;
            '';
          };
        };

        "*.${useACMEHost}" = {
          inherit useACMEHost;
          forceSSL = true;
          default = true;

          locations."/" = {
            proxyPass = "http://192.168.1.230:1080";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_intercept_errors on;
            '';
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
