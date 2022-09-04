{ config, pkgs, inputs, ... }:

let
  # Size in MiB
  biosSize = 1;
  efiSize = 512;
  swapSize = 1024;

  hostName = "drywell";
  admin = "david";

  disk-config = {
    type = "devices";

    content = {
      "disk/by-id/usb-Leef_Supra_0171000000030148-0:0" = {
        type = "table";
        format = "gpt";
        partitions = [
          # Legacy boot partition
          {
            type = "partition";
            part-type = "primary";
            start = "24K";
            end = toString biosSize + "MiB";
            flags = [ "bios_grub" ];
            content.type = "noop";
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
              format = "fat";
              mountpoint = "/boot/efi";
            };
          }

          # Swap
          {
            type = "partition";
            part-type = "primary";
            start = toString (biosSize + efiSize) + "MiB";
            end = toString (biosSize + efiSize + swapSize) + "MiB";
            content.type = "swap";
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

        options = {
          ashift = "12";
          autotrim = "on";

          # Equivalent of `zpool import -R /mnt`
          altroot = "/mnt";
        };

        rootFsOptions = {
          compression = "lz4";
          encryption = "aes-256-gcm";
          keylocation = "prompt";
          keyformat = "passphrase";
          dnodesize = "auto";
          acltype = "posixacl";
          canmount = "off";
          mountpoint = "none";
          normalization = "formD";
          atime = "off";
          xattr = "sa";
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

          rec {
            type = "zfs_filesystem";
            name = "nixos/root";

            options = {
              canmount = "noauto";
              mountpoint = "/";
            };
          }

          rec {
            type = "zfs_filesystem";
            name = "nixos/nix";

            options = {
              canmount = "noauto";
              mountpoint = "/nix";
            };
          }

          ###################
          ### Users Homes ###
          ###################

          rec {
            type = "zfs_filesystem";
            name = "home";

            options = {
              canmount = "off";
              mountpoint = "/home";
            };
          }

          rec {
            type = "zfs_filesystem";
            name = "home/root";

            options = {
              mountpoint = "/root";
            };
          }

          rec {
            type = "zfs_filesystem";
            name = "home/${admin}";
            options.mountpoint = "/home/${admin}";
          }
        ];
      };
    };
  };
in
{
  config = {
    environment.systemPackages = with pkgs; [
      parted
      (writeScriptBin "${hostName}-partition" (inputs.disko.lib.create disk-config))
      (writeScriptBin "${hostName}-mount" (inputs.disko.lib.mount disk-config))
    ];
  };
}
