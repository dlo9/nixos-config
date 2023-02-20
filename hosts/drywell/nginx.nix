{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  dns = "drywell.sigpanic.com";
  useACMEHost = dns;
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

      certs."${dns}" = {
        group = "nginx";
        extraDomainNames = [
          "*.drywell.sigpanic.com"
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
        "webdav.${dns}" = {
          inherit useACMEHost;
          #ocspMustStaple = true;
          #enableACME = true;
          #acmeRoot = null;
          addSSL = true;

          locations."/" = {
            proxyPass = "http://localhost:12345";
            proxyWebsockets = true;
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
