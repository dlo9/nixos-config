{ diskId, adminUser }:

let
  # 1 Gibibit
  GiB = 1024;

  # Partition sizes
  # Total disk 128GB
  # mbrSize = 1;
  mbrSize = 0;
  efiSize = 1 * GiB;
  swapSize = 4 * GiB;

  # ZFS sizes
  reserved = "1G";  # Reserved space for emergency deletions

  diskById = "/dev/disk/by-id/${diskId}";
in
{
  config = {
    disko.devices = {
      # Fast should be an SSD and the main boot device
      disk.fast = {
        type = "disk";
        device = diskById;
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            # MBR
            # {
            #   name = "boot";
            #   start = "0";
            #   end = toString mbrSize + "MiB";
            #   fs-type = "EF02";
            # }

            # UEFI boot partition
            {
              name = "EFI";
              # start = toString mbrSize + "MiB";
              end = toString (mbrSize + efiSize) + "MiB";
              fs-type = "fat32";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }

            # Swap
            {
              name = "swap";
              start = toString (mbrSize + efiSize) + "MiB";
              end = toString (mbrSize + efiSize + swapSize) + "MiB";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            }

            # ZFS system partition
            # This shoud always be last to allow easy growth if the disk is extended
            {
              name = "zfs";
              start = toString (mbrSize + efiSize + swapSize) + "MiB";
              end = "100%";
              content = {
                type = "zfs";
                pool = "fast";
              };
            }
          ];
        };
      };

      zpool.fast = {
        type = "zpool";
        # mode = "mirror";

        # mountpoint = "/";

        options = {
          ashift = "12";
          autotrim = "on";

          # Equivalent of `zpool import -R /mnt`
          # Already specified by disko?
          # altroot = "/mnt";
        };

        rootFsOptions = {
          compression = "zstd";
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          # keylocation = "prompt";
          keylocation = "file:///tmp/fast-key.zfs"; # Only required for remote installation
          dnodesize = "auto";
          acltype = "posixacl";
          canmount = "off";
          mountpoint = "none";
          normalization = "formD";
          atime = "off";
          xattr = "sa";
        };

        postCreateHook = ''
          zfs set keylocation=prompt fast;
          zfs snapshot fast@empty
          zfs mount
        '';

        datasets =
          let
            emptyParent = {
              canmount = "off";
              mountpoint = "none";
            };
          in
          {
            # type = "zfs_fs";
            reserved = {
              type = "zfs_fs";

              options = emptyParent // {
                refreservation = reserved;
              };
            };

            ############
            ### Root ###
            ############

            nixos = {
              type = "zfs_fs";
              options = emptyParent;
            };

            "nixos/root" = {
              type = "zfs_fs";
              options = {
                canmount = "noauto";
                mountpoint = "/";
              };

              mountpoint = "/";
            };

            "nixos/nix" = {
              type = "zfs_fs";
              options = {
                canmount = "noauto";
                mountpoint = "/nix";
              };

              mountpoint = "/nix";
            };

            ###################
            ### Users Homes ###
            ###################

            home = {
              type = "zfs_fs";
              options = {
                canmount = "off";
                mountpoint = "/home";
              };
            };

            "home/${adminUser}" = {
              type = "zfs_fs";
              # options = {
              #   mountpoint = "/home/${adminUser}";
              # };
            };

            ######################
            ### Virtualization ###
            ######################

            virtualization = {
              type = "zfs_fs";
              options = emptyParent;
            };

            "virtualization/containerd" = {
              type = "zfs_fs";
              options = emptyParent;
            };

            "virtualization/containerd/content" = {
              type = "zfs_fs";
              options = {
                mountpoint = "/var/lib/containerd/io.containerd.content.v1.content";
              };
            };

            "virtualization/docker" = {
              type = "zfs_fs";
              options = {
                mountpoint = "/var/lib/docker";
              };
            };

            zfs = {
              type = "zfs_fs";
              options = {
                mountpoint = "/zfs";
              };
            };
          };
      };
    };
  };
}
