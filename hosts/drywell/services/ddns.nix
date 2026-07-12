{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; {
  config = {
    services.ddclient = {
      enable = true;
      protocol = "cloudflare";
      zone = "sigpanic.com";
      username = "token";
      passwordFile = config.sops.secrets.cloudflare-ddns.path;
      domains = ["drywell.sigpanic.com"];
      interval = "5min";
      usev4 = "webv4"; # Public IPv4 from the web (defaults to ipify)
      usev6 = "disabled"; # No IPv6 on this network
    };
  };
}
