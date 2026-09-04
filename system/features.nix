{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    developer-tools.enable = mkEnableOption "developer tools";
    graphical.enable = mkEnableOption "graphical programs";

    # DankMaterialShell subsumes the bar, launcher, notification daemon, lock
    # screen, wallpaper, clipboard history, idle management and night light, so
    # the modules providing those check this flag and stay out of the way when
    # it's set. Turning it off restores the waybar/wofi/mako stack.
    dms.enable =
      mkEnableOption "DankMaterialShell"
      // {default = config.graphical.enable;};

    # Off by default: the login screen is a separate decision from the shell.
    # See system/nixos/graphical/dms.nix for what turning it on changes.
    # Declared here rather than in the NixOS module so the home side can read
    # it on any platform.
    dms.greeter.enable = mkEnableOption "the DankMaterialShell greetd greeter";
  };
}
