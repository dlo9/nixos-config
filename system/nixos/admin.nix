{
  config,
  lib,
  ...
}:
with lib; let
  adminConfig = user: {
    users.users.${user}.extraGroups =
      (optional config.hardware.i2c.enable config.hardware.i2c.group)
      ++ (optional config.networking.networkmanager.enable "networkmanager")
      ++ (optional (config.users.groups ? "wireshark") "wireshark")
      ++ ["dialout"];

    boot.initrd.network.ssh.authorizedKeys = config.users.users.${user}.openssh.authorizedKeys.keys;
  };

  # TODO: move into overlay
  mkMergeTopLevel = names: attrs:
    getAttrs names (
      mapAttrs (k: v: mkMerge v) (foldAttrs (n: a: [n] ++ a) [] attrs)
    );
in {
  options = {
    adminUsers = mkOption {
      type = types.listOf types.nonEmptyStr;
      default = [];
    };

    mainAdmin = mkOption {
      type = types.nullOr types.nonEmptyStr;

      # Defaults to the first listed admin user
      default =
        if ((builtins.length config.adminUsers) == 1)
        then (builtins.elemAt config.adminUsers 0)
        else null;
    };
  };

  config = mkMergeTopLevel ["users" "boot"] (map adminConfig config.adminUsers);
}
