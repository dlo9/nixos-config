{ config, lib, ... }:

with lib;

let
  cfg = config.sys.networking;
in
{
  config = {
    networking = {
      # Use systemd networking, but also keep scripted networking since it's currently only way to get
      # the network working during boot
      useDHCP = true;
      useNetworkd = true;
    };

    services.resolved.domains = [
      "lan"
    ];

    systemd.network = {
      enable = true;

      # Only block boot until a single interface comes online
      wait-online = {
        timeout = 0;
        anyInterface = true;
      };

      networks = {
        "35-wired" = {
          name = "en*";
          DHCP = mkDefault "yes";
          dhcpV4Config.RouteMetric = 1024;
        };

        "35-wireless" = {
          name = "wl*";
          DHCP = mkDefault "yes";
          dhcpV4Config.RouteMetric = 2048; # Prefer wired
        };
      };
    };
  };
}
