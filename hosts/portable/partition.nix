{ config, pkgs, lib, inputs, ... }:

with lib;

let
  # Size in MiB
  biosSize = 1;
  efiSize = 512;
  swapSize = 1024;
  mainDevice = "disk/by-id/usb-Lexar_USB_Flash_Drive_04PRY5BWVCGJ9U83-0:0";

  admin = "david";
  cfg = config.partitionScript;

  disk-config = {
    type = "devices";

    content = {
      "${mainDevice}" = {
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
  options.partitionScript = {
    baseName = mkOption {
      description = "The base name of the partitioning script";
      type = types.nonEmptyStr;
    };
  };

  config = {
    environment.systemPackages = with pkgs; let
      partition-script =
        (writeScriptBin "${cfg.baseName}-partition" (inputs.disko.lib.create disk-config));
    in
    [
      parted
      partition-script
      (writeScriptBin "${cfg.baseName}-mount" (inputs.disko.lib.mount disk-config))
      (writeScriptBin "${cfg.baseName}-install" ''
        set -e

        # DEVICE=$(sed -r "s/DEVICE.*='(.*)'/\1/;t;d" ${partition-script})
        DEVICE="/dev/${mainDevice}"
        if [ -z "$DEVICE" ]; then
          echo "ERROR: Failed to parse device from partitioning script"
          exit 1
        fi

        if [ -z "$SOPS_AGE_KEY" ]; then
          echo "ERROR: SOPSs key not set"
          exit 1
        fi

        if [ "$EUID" -ne "0" ]; then
          echo "ERROR: Must be run as root"
          exit 1
        fi

        wipefs -a "$DEVICE"*

        # Partition the USB
        portable-partition

        # Mount the USB
        umountDevice() {
          swapoff "$DEVICE"-part3
          umount /mnt/boot/efi
          zpool export upool
        }

        trap umountDevice EXIT

        portable-mount

        # Generate the hardware configuration
        # TODO: remove host swap from config
        /etc/nixos/hosts/generate-hardware-config.sh /mnt portable

        # Sync the nix configuration (for easy changes on the host)
        mkdir -p /mnt/etc/nixos
        rsync -a --progress --delete --delete-excluded --exclude="*.log" /etc/nixos/ /mnt/etc/nixos

        # Install initrd keys (for SSH and secrets)
        mkdir /mnt/var

        sops -d --extract '["ssh-keys"]["host"]["rsa"]' /etc/nixos/hosts/portable/secrets.yaml > /mnt/var/ssh_host_rsa_key
        sops -d --extract '["portable"]["private"]' /etc/nixos/sys/secrets/age-keys.yaml > /mnt/var/sops-age-keys.txt

        # Install
        # Impure needed for `fromYaml` for some reason
        nixos-install --flake "path:///mnt/etc/nixos#portable-i686" --root /mnt --impure
      '')
    ];
  };
}
