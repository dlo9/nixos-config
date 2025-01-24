{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  home-manager.users.david.programs.git.extraConfig.safe.directory = "/var/lib/moonraker/config";

  services.gitwatch = {
    klipper = {
      enable = true;
      user = config.home-manager.users.david.home.username;
      remote = "git@github.com:dlo9/trident";
      path = config.services.klipper.mutableConfigFolder;
    };
  };
}
