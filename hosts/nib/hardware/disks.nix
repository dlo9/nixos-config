# Hardware: https://www.minix.us/z83-4-mx
{ diskId, adminUser }:

let
  # 1 Gibibit
  GiB = 1024;

  # Partition sizes
  # Total disk 128GB
  efiSize = 1 * GiB;
  swapSize = 4 * GiB;

  # ZFS sizes
  reserved = "1G";  # Reserved space for emergency deletions
in
{
  disko.devices = {
    # Fast should be an SSD and the main boot device
    disk.fast = {
      type = "disk";
      device = "/dev/disk/by-id/${diskId}";
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

    zpool.fast = {
      type = "zpool";
      mode = "mirror";

      # mountpoint = "/";

      options = {
        ashift = "12";
        autotrim = "on";

        # Equivalent of `zpool import -R /mnt`
        altroot = "/mnt";
      };

      rootFsOptions = {
        compression = "zstd";
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

      postCreateHook = "zfs snapshot fast@empty";

      datasets =
        let
          emptyParent = {
            canmount = "off";
            mountpoint = "none";
          }; in
        {
          # type = "zfs_fs";
          reserved.options = {
            canmount = "off";
            mountpoint = "none";
            refreservation = reserved;
          };

          ############
          ### Root ###
          ############

          nixos.options = emptyParent;

          "nixos/root".options = {
            canmount = "noauto";
            mountpoint = "/";
          };


          "nixos/nix".options = {
            canmount = "noauto";
            mountpoint = "/nix";
          };

          ###################
          ### Users Homes ###
          ###################

          home.options = {
            canmount = "off";
            mountpoint = "/home";
          };

          "home/${adminUser}" = {
            # options = {
            #   mountpoint = "/home/${adminUser}";
            # };
          };

          ######################
          ### Virtualization ###
          ######################

          virtualization.options = emptyParent;
          "virtualization/containerd".options = emptyParent;

          "virtualization/containerd/content".options = {
            mountpoint = "/var/lib/containerd/io.containerd.content.v1.content";
          };

          "virtualization/docker".options = {
            mountpoint = "/var/lib/docker";
          };

          zfs.options = {
            mountpoint = "/zfs";
          };
        };
    };
  };
}
