{
  disk,
  adminUser,
}: let
  # Partition sizes
  efiSize = "1G";
  swapSize = "4G";

  # ZFS sizes
  reserved = "1G"; # Reserved space for emergency deletions
in {
  config = {
    disko.enableConfig = true;

    system.activationScripts = {
      setHomePermissions = ''
        chown david:users /home/david
      '';
    };

    disko.devices = {
      # Fast should be an SSD and the main boot device
      disk.fast = {
        type = "disk";
        device = disk;
        content = {
          type = "gpt";
          partitions = {
            mbr = {
              size = "1M";
              type = "EF02";
            };

            ESP = {
              size = efiSize;
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            swap = {
              size = swapSize;
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };

            fast = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "fast";
              };
            };
          };
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
          keylocation = "file:///tmp/zfs.key"; # Only required for remote installation
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

        datasets = let
          emptyParent = {
            canmount = "off";
            mountpoint = "none";
          };
        in {
          # type = "zfs_fs";
          reserved = {
            type = "zfs_fs";

            options =
              emptyParent
              // {
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
