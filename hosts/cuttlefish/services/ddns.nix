{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
  serviceSettings = rec {
    godns-IPv4 = {
      provider = "Cloudflare";
      login_token = "API Token";
      ip_type = "IPv4";
      proxied = true;
      resolver = "1.1.1.1";
      interval = 300;
      debug_info = true;

      ip_urls = [
        "https://ip4.seeip.org"
        "https://api.ipify.org"
        "https://myip.biturl.top"
        "https://ipecho.net/plain"
        "https://api-ipv4.ip.sb/ip"
      ];

      domains = [
        {
          domain_name = "sigpanic.com";
          sub_domains = ["@"];
        }
      ];
    };

    godns-IPv6 = godns-IPv4 // {
      ip_urls = [];
      ip_type = "IPv6";
      ip_interface = "enp39s0";
    };
  };

  createService = name: settings:
    let
      configFile = pkgs.writeText "godns-${name}.json" (toJSON settings);
    in {
      description = "Dynamic DNS Client";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      restartTriggers = [configFile];

      serviceConfig = rec {
        DynamicUser = true;
        RuntimeDirectory = name;

        ExecStartPre = "!${pkgs.writeShellScript "${name}-prestart" ''
          install --mode=600 --owner=$USER "${configFile}" "/run/${RuntimeDirectory}/godns.json"
          "${pkgs.replace-secret}/bin/replace-secret" "API Token" "${config.sops.secrets.cloudflare-ddns.path}" "/run/${RuntimeDirectory}/godns.json"
        ''}";

        ExecStart = "${pkgs.godns}/bin/godns -c /run/${RuntimeDirectory}/godns.json";
      };
    };
in {
  config.systemd.services = mapAttrs createService serviceSettings;
}
