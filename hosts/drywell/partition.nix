{
  config,
  pkgs,
  inputs,
  ...
}: let
  # Size in MiB
  biosSize = 1;
  efiSize = 1024;
  swapSize = 8 * 1024;
  reservedSize = "15G";
  containerdSize = "30G";

  hostName = "drywell";
  admin = "david";

  disk-config = {
    type = "devices";

    content = {
      "disk/by-id/nvme-Force_MP500_17037932000122530025" = {
        type = "table";
        format = "gpt";
        partitions = [
          # Legacy boot partition
          {
            type = "partition";
            part-type = "primary";
            start = "24K";
            end = toString biosSize + "MiB";
            flags = ["bios_grub"];
            content.type = "noop";
          }

          # UEFI boot
          {
            type = "partition";
            part-type = "primary";
            start = toString biosSize + "MiB";
            end = toString (biosSize + efiSize) + "MiB";
            bootable = true;
            content = {
              type = "filesystem";
              format = "fat";
              mountpoint = "/boot/efi0";
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
              pool = "fast";
            };
          }
        ];
      };

      fast = {
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
              refreservation = reservedSize;
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
              mountpoint = "/";
            };
          }

          {
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
            options.mountpoint = "/home/${admin}";
          }

          ########################
          ### Containerization ###
          ########################

          {
            type = "zfs_filesystem";
            name = "containers";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          }

          {
            type = "zfs_filesystem";
            name = "containers/containerd";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          }

          {
            type = "zfs_filesystem";
            name = "containers/containerd/content";
            options = {
              mountpoint = "/var/lib/containerd/io.containerd.content.v1.content";
            };
          }

          {
            type = "zfs_volume";
            name = "containers/containerd/overlayfs-snapshotter";
            size = "${containerdSize}";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs";
            };
          }

          {
            type = "zfs_filesystem";
            name = "containers/kubernetes";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          }

          {
            type = "zfs_filesystem";
            name = "containers/kubernetes/storage";
            options = {
              canmount = "off";
              mountpoint = "none";
            };
          }

          {
            type = "zfs_filesystem";
            name = "containers/docker";
            options = {
              mountpoint = "/var/lib/docker";
            };
          }

          {
            type = "zfs_filesystem";
            name = "zfs";
            options = {
              mountpoint = "/zfs";
            };
          }
        ];
      };
    };
  };
in {
  config = {
    environment.systemPackages = with pkgs; [
      parted
      (writeScriptBin "${hostName}-partition" (inputs.disko.lib.create disk-config))
      (writeScriptBin "${hostName}-mount" (inputs.disko.lib.mount disk-config))
    ];
  };
}
