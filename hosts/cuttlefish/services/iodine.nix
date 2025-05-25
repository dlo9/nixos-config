{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  config = {
    services.iodine.server = {
      enable = true;
      ip = "10.10.0.1/24";
      # ip = "172.16.0.1/24";
      domain = "vpn.sigpanic.com";
      # domain = "kira.ns.cloudflare.com";
      # extraConfig = "-p 53535 -l 0.0.0.0";
      # extraConfig = "-l 192.168.0.230 -D -c -d iodine";

      # extraConfig = "-l 192.168.0.230 -d iodine -n auto -c";
      # extraConfig = "-d iodine -n auto -c -DD";
      extraConfig = "-d iodine -n auto -c -D";
      # extraConfig = "-d iodine -c -D";
      passwordFile = config.sops.secrets."iodine".path;
    };

    networking.firewall.allowedUDPPorts = [
      53
      # 53535
    ];

    networking.nat = {
      enable = true;
      internalInterfaces = ["iodine"];
      externalInterface = "cuttlefish";
    };
  };
}
