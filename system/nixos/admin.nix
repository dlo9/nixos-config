{
  config,
  lib,
  ...
}:
with lib; let
  adminConfig = user: {
    users.users.${user}.extraGroups = (optional config.hardware.i2c.enable config.hardware.i2c.group) ++ ["dialout"];

    boot.initrd.network.ssh.authorizedKeys = config.users.users.${user}.openssh.authorizedKeys.keys;
  };

  # TODO: move into overlay
  mkMergeTopLevel = names: attrs:
    getAttrs names (
      mapAttrs (k: v: mkMerge v) (foldAttrs (n: a: [n] ++ a) [] attrs)
    );
in {
  config = mkMergeTopLevel ["users" "boot"] (map adminConfig config.adminUsers);
}
