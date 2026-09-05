{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    developer-tools.enable = mkEnableOption "developer tools";
    graphical.enable = mkEnableOption "graphical programs";

    # DMS subsumes the bar, launcher, notification daemon, lock screen,
    # wallpaper, clipboard history, idle management and night light; the
    # modules providing those check this flag and stay out of the way. Off
    # restores the waybar/wofi/mako stack.
    dms.enable =
      mkEnableOption "DankMaterialShell"
      // {default = config.graphical.enable;};

    # Declared here rather than in the NixOS module so the home side can read
    # it on any platform. See system/nixos/graphical/dms.nix.
    dms.greeter.enable = mkEnableOption "the DankMaterialShell greetd greeter";
  };
}
