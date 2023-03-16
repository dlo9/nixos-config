{ config, pkgs, lib, ... }:

with lib;

{
  config = {
    systemd.network.networks = {
      # Bond ethernet devices into a "lan" device
      "35-wired" = {
        bond = [ "lan" ];
        DHCP = "no";
      };

      # Disable wireless
      "35-wireless".DHCP = "no";

      # Configure "lan"
      "40-lan" = {
        name = "lan";
        DHCP = "yes";
        dhcpV4Config.RouteMetric = 512;
      };

      # Create "lan"
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
