{
  config,
  lib,
  ...
}:
with lib; let
  adminConfig = user: {
    users.users.${user}.extraGroups = optional config.hardware.i2c.enable config.hardware.i2c.group;

    boot.initrd.network.ssh.authorizedKeys = config.users.users.${user}.openssh.authorizedKeys.keys;
  };
in {
  # config = mkMerge (map adminConfig config.admin-users);

  config = {
    users.users = listToAttrs (map (user: {
        name = user;
        value = {extraGroups = optional config.hardware.i2c.enable config.hardware.i2c.group;};
      })
      config.admin-users);
  };
}
