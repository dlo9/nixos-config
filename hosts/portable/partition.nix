{ config, pkgs, inputs, ... }:

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
      "disk/by-id/usb-Lexar_USB_Flash_Drive_04PRY5BWVCGJ9U83-0:0" = {
        #"disk/by-id/usb-Generic_Flash_Disk_9D63220B-0:0" = {
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
            # TODO: mkswap
            #content.type = "noop";
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
        # mode = "mirror";

        #mountpoint = "/mnt";

        options = {
          ashift = "12";
          autotrim = "on";

          # Equivalent of `zpool import -R /mnt`
          # cachefile = "none";
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
            #mountpoint = "/";

            options = {
              canmount = "noauto";
              #inherit mountpoint;
              mountpoint = "/";
            };
          }

          rec {
            type = "zfs_filesystem";
            name = "nixos/nix";
            #mountpoint = "/nix";

            options = {
              canmount = "noauto";
              #inherit mountpoint;
              mountpoint = "/nix";
            };
          }

          ###################
          ### Users Homes ###
          ###################

          rec {
            type = "zfs_filesystem";
            name = "home";
            #mountpoint = "/home";

            options = {
              canmount = "off";
              #inherit mountpoint;
              mountpoint = "/home";
            };
          }

          rec {
            type = "zfs_filesystem";
            name = "home/root";
            #mountpoint = "/root";

            options = {
              #inherit mountpoint;
              mountpoint = "/root";
            };
          }

          rec {
            type = "zfs_filesystem";
            name = "home/${admin}";
            options.mountpoint = "/home/${admin}";
            #options.mountpoint = "none";
            #mountpoint = "/home";
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
