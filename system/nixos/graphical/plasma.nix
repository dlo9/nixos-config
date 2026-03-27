{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  enabled = config.services.desktopManager.plasma6.enable;
in {
  # The Plasma Wayland session startup imports its wrapper environment into
  # the systemd user manager, overriding environment.d generators. This means
  # plasmashell doesn't see /run/current-system/sw/share in XDG_DATA_DIRS
  # and crashes with "starting invalid corona".
  # Fix: use Plasma's env hook (plasma-workspace/env/*.sh) which is sourced
  # by startplasma-wayland before importing environment into systemd.
  environment.etc."xdg/plasma-workspace/env/nixos-xdg.sh" = mkIf enabled {
    text = ''
      . /etc/set-environment
    '';
  };

  services.displayManager = {
    enable = mkDefault enabled;
    defaultSession = mkIf enabled (mkDefault "plasma");
    autoLogin = mkIf enabled {
      enable = mkDefault true;
      user = mkDefault config.mainAdmin;
    };

    sddm = {
      enable = mkDefault enabled;
      wayland.enable = mkDefault enabled;
      autoLogin.relogin = mkDefault true;
    };
  };
}
