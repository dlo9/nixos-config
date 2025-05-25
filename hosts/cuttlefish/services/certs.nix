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
    # ACME definition
    security.acme = {
      acceptTerms = true;

      defaults = {
        # Testing environment
        #server = "https://acme-staging-v02.api.letsencrypt.org/directory";

        email = "if_coding@fastmail.com";
        dnsProvider = "cloudflare";
        credentialsFile = config.sops.secrets.cloudflare-dns.path;
        extraLegoFlags = [
          # Since my router intercepts and caches DNS traffic, DNS propagation detection
          # for short TTLs doesn't work. Instead, wait 30s for TXT record to propagate.
          "--dns.propagation-wait=30s"
        ];
      };

      certs."${useACMEHost}" = {
        #ocspMustStaple = true;
        extraDomainNames = [
          "*.${useACMEHost}"
        ];
      };
    };
  };
}
