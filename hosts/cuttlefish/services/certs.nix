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
in {
  config = {
    # DNS provider auth
    sops.secrets.cloudflare-dns = {
      sopsFile = config.sys.secrets.hostSecretsFile;
    };

    # ACME definition
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
        # group = "nginx";
        extraDomainNames = [
          "*.sigpanic.com"
        ];
      };
    };
  };
}
