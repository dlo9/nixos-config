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

    services.resolved.domains = [
      "lan"
    ];

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
