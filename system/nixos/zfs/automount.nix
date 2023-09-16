{
  lib,
  utils,
  ...
}:
with lib; {
  options = {
    # This configures zfs datasets to be managed by zfs utilities after boot as opposed to Nix. These are the recommended options
    # in the Nix ZFS wiki, and so this automatically adds them so that hardware config doesn't need to be modified.
    fileSystems = with types;
      mkOption {
        type = attrsOf (submodule ({
          name,
          config,
          ...
        }: {
          options.zfsManaged = mkOption {
            description = "Let zfsutils manage the mount";
            type = bool;

            # Any filesystems marked "neededForBoot" need to have mountpoint=legacy since initrd will mount them manually:
            # https://search.nixos.org/options?channel=22.11&show=fileSystems.%3Cname%3E.neededForBoot
            default = mkDefault (config.fsType == "zfs" && !(builtins.elem name utils.pathsNeededForBoot));

            # When visible, it triggers a *long* build of the nixos man pages with each rebuild
            visible = false;
          };

          config.options = mkIf config.zfsManaged [
            "zfsutil"
            "X-mount.mkdir"
            "nofail"
          ];
        }));
      };
  };
}
