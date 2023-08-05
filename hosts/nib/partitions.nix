# Hardware: https://www.minix.us/z83-4-mx

let
  # 1 Gibibit
  GiB = 1024;

  # Partition sizes
  # Total disk 128GB
  efiSize = 1 * GiB;
  swapSize = 8 * GiB;
  reserved = 1 * GiB;  # Reserved space for emergency deletions
in
{
  disko.devices = {
    # Fast should be an SSD and the main boot device
    disk.fast = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          # UEFI boot partition
          {
            name = "EFI";
            start = "0";
            end = toString efiSize + "MiB";
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
            start = toString efiSize + "MiB";
            end = toString (efiSize + swapSize) + "MiB";
            # part-type = "primary";
            content = {
              type = "swap";
              randomEncryption = true;
            };
          }

          # ZFS system partition
          # This shoud always be last to allow easy growth if the disk is extended
          {
            name = "zfs";
            start = toString (efiSize + swapSize) + "MiB";
            end = "100%";
            content = {
              type = "zfs";
              pool = "fast";
            };
          }
        ];
      };
    };

    # EXAMPLE
    disk = {
      fast = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "ESP";
              start = "0";
              end = "64MiB";
              fs-type = "fat32";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            }
            {
              name = "zfs";
              start = "128MiB";
              end = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            }
          ];
        };
      };
      y = {
        type = "disk";
        device = builtins.elemAt disks 1;
        content = {
          type = "table";
          format = "gpt";
          partitions = [
            {
              name = "zfs";
              start = "128MiB";
              end = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            }
          ];
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          compression = "lz4";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/";
        postCreateHook = "zfs snapshot zroot@blank";

        datasets = {
          zfs_fs = {
            type = "zfs_fs";
            mountpoint = "/zfs_fs";
            options."com.sun:auto-snapshot" = "true";
          };
          zfs_unmounted_fs = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          zfs_legacy_fs = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/zfs_legacy_fs";
          };
          zfs_testvolume = {
            type = "zfs_volume";
            size = "10M";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/ext4onzfs";
            };
          };
          encrypted = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///tmp/secret.key";
            };
            postCreateHook = ''
              zfs set keylocation="prompt" "zroot/$name";
            '';
          };
          "encrypted/test" = {
            type = "zfs_fs";
            mountpoint = "/zfs_crypted";
          };
        };
      };
    };
  };
}
