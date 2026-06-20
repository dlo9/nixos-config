# Check set values: zfs get -s local all fast
# Dry run: nixos-rebuild dry-activate --flake .#pavil --sudo
{inputs, ...}: let
  GB = 1024 * 1024 * 1024;
in {
  imports = [
    inputs.disko-zfs.nixosModules.default
  ];

  disko.zfs = {
    enable = true;

    settings = {
      # Runtime properties written by the zfs-shutdown service, not config.
      ignoredProperties = ["nixos:*"];

      datasets = let
        # Marker for parent containers that only group children.
        container = {
          mountpoint = "none";
          canmount = "off";
        };
      in {
        # Pool root: holds the inherited defaults for every child dataset.
        "fast".properties =
          container
          // {
            compression = "zstd";
            atime = "off";
            xattr = "sa";
            dnodesize = "auto";
            acltype = "posix";
            keylocation = "prompt";
          };

        # Emergency free space, reserved so the pool can never fully fill
        "fast/reserved".properties =
          container
          // {
            refreservation = 50 * GB;
          };

        ############
        ### Root ###
        ############

        "fast/nixos".properties = container;

        # `/` and `/nix` are manually mounted in initrd, not by ZFS
        "fast/nixos/root".properties.mountpoint = "legacy";
        "fast/nixos/nix".properties.mountpoint = "legacy";

        ###################
        ### Users Homes ###
        ###################

        "fast/home".properties = {
          mountpoint = "/home";
          canmount = "off";
        };

        # Child datasets (.cache, Downloads, code) inherit their mountpoint
        # from this dataset, so only the parent needs an explicit mountpoint.
        "fast/home/david".properties = {
          mountpoint = "/home/david";
          dnodesize = "auto";
          acltype = "posix";
        };

        "fast/home/david/.cache".properties = {};
        "fast/home/david/Downloads".properties = {};
        "fast/home/david/code".properties = {};

        "fast/home/root".properties = {
          mountpoint = "/root";
        };

        #############
        ### Games ###
        #############

        "fast/games".properties =
          container
          // {
            dnodesize = "auto";
            acltype = "posix";
          };

        "fast/games/lutris".properties = {
          mountpoint = "/home/david/.local/share/lutris";
        };

        "fast/games/steam".properties = {
          mountpoint = "/home/david/.local/share/Steam";
        };
      };
    };
  };
}
