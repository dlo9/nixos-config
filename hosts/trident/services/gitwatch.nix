{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  home-manager.users.david.programs.git.settings.safe.directory = "/var/lib/moonraker/config";

  services.gitwatch = {
    klipper = {
      enable = true;
      user = config.home-manager.users.david.home.username;
      remote = "ssh://git@git.sigpanic.com:2222/david/trident.git";
      path = config.services.klipper.configDir;
    };
  };
}
