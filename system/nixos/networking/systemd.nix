{
  config,
  lib,
  ...
}:
with lib; let
  useNM = config.networking.networkmanager.enable;

  # Addressing for the physical interfaces. Bound out here because the two
  # consumers below disagree about when it applies: initrd always wants it, the
  # booted system only when NetworkManager isn't around.
  physicalNetworks = {
    "35-wired" = {
      matchConfig.Name = ["en*" "eth*"];
      DHCP = mkDefault "yes";
      dhcpV4Config.RouteMetric = 1024;
      domains = config.services.resolved.settings.Resolve.Domains;

      # Explicitly enable IPv6 Router Advertisement acceptance for SLAAC
      networkConfig = {
        IPv6AcceptRA = true;
      };
    };

    "35-wireless" = {
      name = "wl*";
      DHCP = mkDefault "yes";
      dhcpV4Config.RouteMetric = 2048; # Prefer wired
      domains = config.services.resolved.settings.Resolve.Domains;

      # Explicitly enable IPv6 Router Advertisement acceptance for SLAAC
      networkConfig = {
        IPv6AcceptRA = true;
      };
    };
  };
in {
  config = {
    # Initrd network should be the same as after boot
    boot.initrd.systemd.network =
      config.systemd.network
      // {
        # ...except initrd has no NetworkManager, and this carries the SSH
        # session for remote unlock of the encrypted pool, so the physical
        # interfaces are merged back in unconditionally.
        networks = config.systemd.network.networks // physicalNetworks;
      };

    networking.useNetworkd = mkDefault true;
    networking.dhcpcd.enable = mkDefault false;

    services.resolved = {
      enable = true;
      settings.Resolve = {
        # Enable Quad9 DOT
        DNSOverTLS = "opportunistic";
        Domains = ["home.arpa"];
        FallbackDNS = [
          "9.9.9.9"
          "149.112.112.112"
          "2620:fe::fe"
          "2620:fe::9"
        ];
      };
    };

    systemd.network = {
      enable = mkDefault true;

      # Only block boot until a single interface comes online
      wait-online = {
        timeout = 0;
        anyInterface = mkDefault true;
      };

      # NetworkManager does its own addressing, so a matching .network file
      # would put a second DHCP client on the link. nixpkgs drops its generated
      # equivalents via networking.useDHCP = false, which has no effect on
      # hand-declared units. 50-wg0 and 50-tailscale stay: those interfaces are
      # networkd's, and NM is told to keep off them in vpn.nix.
      networks = optionalAttrs (!useNM) physicalNetworks;
    };
  };
}
