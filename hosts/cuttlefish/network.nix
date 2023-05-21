{ config, pkgs, lib, ... }:

# Resources:
# - [systemd example](https://gist.github.com/maddes-b/e487d1f95f73f5d40805315f0232d5d9)
# - [Bridge vs Macvlan](https://hicu.be/bridge-vs-macvlan)

with lib;
let
  MACs = {
    cuttlefish = "d8:bb:c1:c8:5c:da";
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
      links = {
        # Randomize MAC of physical links
        "10-host" = {
          matchConfig.Type = "ether";
          linkConfig = {
            MACAddressPolicy = "random";
            NamePolicy = "path";
          };
        };
      };

      networks = {
        # Disable DHCP on physical links and add the host's vlan
        "35-wired" = {
          DHCP = "no";

          macvlan = [
            "cuttlefish"
          ];
        };

        # Disable wireless
        "35-wireless".DHCP = "no";

        # Enable DHCP for cuttlefish's vlan
        "40-cuttlefish" = {
          name = "cuttlefish";
          DHCP = "yes";
          dhcpV4Config.Hostname = "cuttlefish";
        };
      };

      netdevs = {
        # Virtual network card for cuttlefish
        "15-cuttlefish" = {
          netdevConfig = {
            Kind = "macvlan";
            Name = "cuttlefish";
            MACAddress = MACs.cuttlefish;
          };

          macvlanConfig = {
            Mode = "bridge";
          };
        };
      };
    };
  };
}
