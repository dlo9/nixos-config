{
  config,
  lib,
  ...
}:
with lib; {
  config = {
    # Initrd network should be the same as after boot
    boot.initrd.systemd.network = config.systemd.network;

    networking.useNetworkd = mkDefault true;
    networking.dhcpcd.enable = mkDefault false;

    services.resolved = {
      domains = ["home.arpa"];

      # Enable Quad9 DNS over TLS
      dnsovertls = "opportunistic";
      fallbackDns = [
        "9.9.9.9"
        "149.112.112.112"
        "2620:fe::fe"
        "2620:fe::9"
      ];
    };

    systemd.network = {
      enable = mkDefault true;

      # Only block boot until a single interface comes online
      wait-online = {
        timeout = 0;
        anyInterface = mkDefault true;
      };

      networks = {
        "35-wired" = {
          matchConfig.Name = ["en*" "eth*"];
          DHCP = mkDefault "yes";
          dhcpV4Config.RouteMetric = 1024;
          domains = config.services.resolved.domains;
        };

        "35-wireless" = {
          name = "wl*";
          DHCP = mkDefault "yes";
          dhcpV4Config.RouteMetric = 2048; # Prefer wired
          domains = config.services.resolved.domains;
        };
      };
    };
  };
}
