{ config, pkgs, lib, ... }:

with lib;

{
  config = {
    # Use systemd-networkd
    networking = {
      # Use systemd networking, but also keep scripted networking since it's currently only way to get
      # the network working during boot
      useDHCP = true;
      useNetworkd = true;
    };

    systemd.network = {
      enable = true;

      # Only block boot until a single interface comes online
      wait-online = {
        # timeout = 60;
        timeout = 0;
        anyInterface = true;
      };

      networks = {
        "35-wired" = {
          name = "en*";
          bond = [ "lan" ];
          dhcpV4Config.RouteMetric = 1024;
        };

        "35-wireless" = {
          name = "wl*";
          dhcpV4Config.RouteMetric = 2048; # Prefer wired
        };

        "40-lan" = {
          name = "lan";
          DHCP = "yes";
          dhcpV4Config.RouteMetric = 512;
        };
      };

      netdevs."10-lan" = {
        netdevConfig = {
          Kind = "bond";
          Name = "lan";

          # FUTURE: Use a locally administered, unicast address like "02:9e:8d:a6:ea:d5"
          # Only downside is that it won't get the same IP during init and after init
          MACAddress = "00:25:90:91:fd:ab";
        };

        bondConfig.MIIMonitorSec = "1s";
      };
    };
  };
}
