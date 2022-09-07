{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  zreplDefaults = {
    pruning = {
      keep_sender = [
        { type = "not_replicated"; }

        # Keep everything
        {
          type = "regex";
          regex = ".*";
        }
      ];

      keep_receiver = [
        # Keep everything
        {
          type = "regex";
          regex = ".*";
        }
      ];
    };
  };
in
{
  imports = [
    ./hardware.nix
  ];

  config = {
    sys = {
      gaming.enable = false;
      development.enable = false;
      graphical.enable = false;
      # TODO: kubernetes
    };

    boot.kernelParams = [ "nomodeset" ];
    boot.loader = {
      grub.mirroredBoots = [
        { devices = [ "/dev/disk/by-id/nvme-Force_MP500_17037932000122530025" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
      ];
    };

    networking.interfaces.enp1s0.useDHCP = true;

    # Ethernet modules for remote boot login
    boot.initrd.kernelModules = [
      "r8169"
    ];

    # ZFS autosnapshot and replication
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
          (recursiveUpdate zreplDefaults {
            name = "drywell replication";
            type = "pull";
            root_fs = "slow/replication/drywell"; # This must exist
            interval = "1h";

            connect = {
              type = "tcp";
              address = "192.168.1.200:8888";
            };

            recv = {
              # https://zrepl.github.io/configuration/sendrecvoptions.html#placeholders
              placeholder.encryption = "inherit";
              properties.override = {
                canmount = "off";
                refreservation = "none";
              };
            };
          })
        ];
      };
    };
  };
}
