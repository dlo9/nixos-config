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
    sops.secrets.cloudflare-dns = {
      sopsFile = config.sys.secrets.hostSecretsFile;
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
        "webdav.${useACMEHost}" = {
          inherit useACMEHost;
          addSSL = true;

          locations."/" = {
            proxyPass = "http://localhost:12345";
            proxyWebsockets = true;
            extraConfig = ''
              client_max_body_size 50M;
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
