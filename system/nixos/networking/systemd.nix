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

      networks = {
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
    };
  };
}
