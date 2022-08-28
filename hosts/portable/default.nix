{ config, pkgs, lib, inputs, ... }:

let
  # Size in MiB
  biosSize = 1;
  efiSize = 512;
  swapSize = 1024;

  hostName = "portable";
  admin = "david";

  disk-config = {
    type = "devices";

    content = {
      # /dev/disk/by-id/
      "usb-Generic_Flash_Disk_9D63220B-0:0" = {
        type = "table";
        format = "gpt";
        partitions = [
          # Legacy boot partition
          {
            type = "partition";
            part-type = "primary";
            start = "24K";
            end = toString biosSize + "MiB";
            #bootable = true;
            flags = [ "bios_grub" ];
            content.type = "noop";
            # content = {
            #   type = "filesystem";
            #   format = "ext4";
            #   mountpoint = "/";
            # };
          }

          # UEFI boot
          {
            type = "partition";
            part-type = "primary";
            start = toString (biosSize) + "MiB";
            end = toString (biosSize + efiSize) + "MiB";
            bootable = true;
            content = {
              type = "filesystem";
              format = "fat32";
              mountpoint = "/boot/efi0";
            };
          }

          # Swap
          {
            type = "partition";
            part-type = "primary";
            start = toString (biosSize + efiSize) + "MiB";
            end = toString (biosSize + efiSize + swapSize) + "MiB";
            # TODO: mkswap
          }

          # Main
          {
            type = "partition";
            part-type = "primary";
            start = toString (biosSize + efiSize + swapSize) + "MiB";
            end = "100%";
            content = {
              type = "zfs";
              pool = "upool";
            };
          }
        ];
      };

      upool = {
        type = "zpool";
        # mode = "mirror";

        rootFsOptions = {
          compression = "lz4";
          encryption = "aes-256-gcm";
          keylocation = "prompt";
          keyformat = "passphrase";
          dnodesize = "auto";
          ashift = "12";
          autotrim = "on";
          acltype = "posixacl";
          canmount = "off";
          normalization = "formD";
          atime = "off";
          xattr = "sa";

          # Equivalent of `zpool import -R /mnt`
          cachefile = "none";
          altroot = "/mnt";
        };

        datasets = [
          {
            type = "zfs_filesystem";
            name = "reserved";
            options = {
              canmount = "off";
              mountpoint = "none";
              refreservation = "1G";
            };
          }

          ############
          ### Root ###
          ############

          {
            type = "zfs_filesystem";
            name = "nixos";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          }

          {
            type = "zfs_filesystem";
            name = "nixos/root";
            options = {
              canmount = "noauto";
              # TODO: Mount it now, or the mount later will overlay the other dataset mounts and `zpool export` can fail
              mountpoint = "/";
            };
          }

          ###################
          ### Users Homes ###
          ###################

          {
            type = "zfs_filesystem";
            name = "home";
            options = {
              canmount = "off";
              mountpoint = "/home";
            };
          }

          {
            type = "zfs_filesystem";
            name = "home/root";
            options = {
              mountpoint = "/root";
            };
          }

          {
            type = "zfs_filesystem";
            name = "home/${admin}";
          }
        ];
      };
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
    };

    boot.kernelParams = [ "nomodeset" ];
    boot.loader = {
      efi.canTouchEfiVariables = false;
      grub.efiInstallAsRemovable = true;

      grub.mirroredBoots = [
        { devices = [ "/dev/disk/by-id/ata-KINGSTON_SNS4151S332G_50026B724500626D" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
      ];
    };

    environment.systemPackages = with pkgs; [
      (pkgs.writeScriptBin "${hostName}-partition" (disko.create disk-config))
      (pkgs.writeScriptBin "${hostName}-mount" (disko.mount disk-config))
    ];
  };
}
