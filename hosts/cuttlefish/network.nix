{ config, pkgs, lib, ... }:

# Resources:
# - [systemd example](https://gist.github.com/maddes-b/e487d1f95f73f5d40805315f0232d5d9)
# - [Bridge vs Macvlan](https://hicu.be/bridge-vs-macvlan)

with lib;
let
  MACs = {
    # IP: 192.168.1.228
    host = "d8:bb:c1:c8:5c:da";

    # Non-host generated with https://www.hellion.org.uk/cgi-bin/randmac.pl?scope=global&oui=&type=unicast
    winvm = "00:00:00:e8:cb:52";
  };
in
{
  config = {
    # Enable IP forwarding for tailscale, kubernetes, and VMs
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkForce 1;
      "net.ipv6.conf.all.forwarding" = lib.mkForce 1;

      # For macvlan
      "net.ipv4.conf.all.arp_filter" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
    };

    systemd.network = {
      networks = {
        "35-wired" = {
          DHCP = "yes";

          macvlan = [
            "winvm"
          ];
        };

        # Disable wireless
        "35-wireless".DHCP = "no";

        # Configure winvm
        "40-winvm" = {
          name = "winvm";
          DHCP = "yes";
          dhcpV4Config.Hostname = "winvm";
        };
      };

      netdevs = {
        # Virtual network card for winvm
        "10-winvm" = {
          netdevConfig = {
            Kind = "macvlan";
            Name = "winvm";
            MACAddress = MACs.winvm;
          };

          macvlanConfig = {
            Mode = "bridge";
          };
        };
      };
    };
  };
}
