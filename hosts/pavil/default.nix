{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
    networking.interfaces.wlo1.useDHCP = true;

    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
    ];

    # Bluetooth
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    # Enable A2DP Sink: https://nixos.wiki/wiki/Bluetooth
    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };

    # Auto-switch to new bluetooth devices
    hardware.pulseaudio.extraConfig = "
      load-module module-switch-on-connect
    ";

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8888 ];
    services.zrepl = {
      enable = true;
      settings = {
        global = {
          logging = [
            {
              type = "stdout";
              level = "warn";
              format = "human";
              time = true;
              color = true;
            }
          ];
        };

        jobs = [
          {
            name = "cuttlefish replication";
            type = "source";

            serve = {
              type = "tcp";
              #listen = ":8888";
              #listen_freebind: true;
              listen = "100.111.108.84:8888";
              clients = {
                "100.97.145.42" = "cuttlefish";
              };
            };

            filesystems = {
              "<" = true;
            };

            send = {
              encrypted = true;
              large_blocks = true;
              compressed = true;
              embedded_data = true;
              raw = true;
              #saved = true;
            };

            snapshotting = {
              type = "periodic";
              prefix = "auto-";
              interval = "15m";
            };
          }
        ];
      };
    };
  };
}
