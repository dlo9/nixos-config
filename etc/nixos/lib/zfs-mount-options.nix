# TODO: merge this into zfs.nix

# This add an option `zfsUtils` to filesystems which configures zfs datasets to be mounted
# by zfs utilities after boot as opposed to nix directly. These are the recommended options
# in the Nix ZFS wiki, but prevents the options from being cleared when the hardware config
# is regenerated

{ config, pkgs, lib, ... }: { 
  options = with lib; with types; {
    fileSystems = mkOption {
      type = attrsOf (submodule ({config, ...}: {
        options.zfsUtils = mkOption {
          default = true;
          description = "Mount using zfs utils if this is a non-root zfs mount";
          type = bool;
        };

        # TODO: check root
        config.options = mkIf (config.zfsUtils && config.fsType == "zfs") [
          "zfsutil"
          "X-mount.mkdir"
        ];
      }));
    };
  };

  config = {
    fileSystems."/".zfsUtils = false;
  };
}
