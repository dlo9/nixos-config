{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
  configFile = pkgs.writeText "godns.json" (toJSON {
    provider = "Cloudflare";
    login_token = "API Token";
    ip_type = "IPv4";
    proxied = true;
    resolver = "8.8.8.8";
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
  });

  RuntimeDirectory = "godns";
in {
  config = {
    systemd.services.godns = {
      description = "Dynamic DNS Client";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      restartTriggers = [configFile];

      serviceConfig = {
        DynamicUser = true;
        inherit RuntimeDirectory;
        ExecStartPre = "!${pkgs.writeShellScript "godns-prestart" ''
          install --mode=600 --owner=$USER "${configFile}" "/run/${RuntimeDirectory}/godns.json"
          "${pkgs.replace-secret}/bin/replace-secret" "API Token" "${config.sops.secrets.cloudflare-ddns.path}" "/run/${RuntimeDirectory}/godns.json"
        ''}";

        ExecStart = "${pkgs.godns}/bin/godns -c /run/${RuntimeDirectory}/godns.json";
      };
    };
  };
}
