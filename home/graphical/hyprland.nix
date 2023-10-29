{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  ...
}:
with lib;
with types;
with builtins; {
  config = mkIf (config.graphical.enable && isLinux) {
    xdg = {
      enable = mkDefault true;

      configFile = {
        # Set wallpaper
        "hypr/hyprpaper.conf".text = ''
          ipc = off
          preload = ${config.wallpapers.default}
          wallpaper = , ${config.wallpapers.default}
        '';
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      plugins = [];

      # https://wiki.hyprland.org/Configuring/Variables/
      settings = {
        # Startup services
        exec-once = [
          # Notifications
          "${config.services.mako.package}/bin/mako"

          # Authentication agent
          "polkit-agent"

          # Clipboard manager
          "${pkgs.copyq}/bin/copyq"

          # Search for desktop entries
          "${pkgs.dex}/bin/dex -a -s /etc/xdg/autostart/:~/.config/autostart/"

          # Status Bar
          # TODO: switch to eww: https://wiki.hyprland.org/Useful-Utilities/Status-Bars/#eww
          "${config.programs.waybar.package}/bin/waybar"

          # Wallpaper
          # TODO: doesn't restart when config is changed
          "${pkgs.hyprpaper}/bin/hyprpaper"
        ];

        # Monitors
        monitor = [
          ", preferred, auto, 1" # Default
          # "DP-1, highres, 0x0, 1"
        ];

        bind = let
          mod = "ALT";
        in [
          # Open terminal
          "${mod}, RETURN, exec, alacritty"

          # Open the power menu
          "${mod} + SHIFT, E, exec, ${pkgs.callPackage ./waybar/power.nix {}}/bin/power.sh"

          # Close the focused window
          "${mod} + SHIFT, Q, killactive"

          # Start the application launcher
          "${mod}, D, exec, ${pkgs.wofi}/bin/wofi -c ~/.config/wofi/config -I"

          # Reload
          "${mod} + SHIFT, R, forcerendererreload"

          # Lock
          # "${mod} + SHIFT, L, UNIMPLEMENTED"

          # Move focus
          "${mod}, left, movefocus, l"
          "${mod}, right, movefocus, r"
          "${mod}, up, movefocus, u"
          "${mod}, down, movefocus, d"

          # Move focus to workspaces
          "${mod}, 1, workspace, 1"
          "${mod}, 2, workspace, 2"
          "${mod}, 3, workspace, 3"
          "${mod}, 4, workspace, 4"
          "${mod}, 5, workspace, 5"
          "${mod}, 6, workspace, 6"
          "${mod}, 7, workspace, 7"
          "${mod}, 8, workspace, 8"
          "${mod}, 9, workspace, 9"
          "${mod}, 0, workspace, 10"

          # Move window to workspaces
          "${mod} + SHIFT, 1, movetoworkspace, 1"
          "${mod} + SHIFT, 2, movetoworkspace, 2"
          "${mod} + SHIFT, 3, movetoworkspace, 3"
          "${mod} + SHIFT, 4, movetoworkspace, 4"
          "${mod} + SHIFT, 5, movetoworkspace, 5"
          "${mod} + SHIFT, 6, movetoworkspace, 6"
          "${mod} + SHIFT, 7, movetoworkspace, 7"
          "${mod} + SHIFT, 8, movetoworkspace, 8"
          "${mod} + SHIFT, 9, movetoworkspace, 9"
          "${mod} + SHIFT, 0, movetoworkspace, 10"

          # Fullscreen
          "${mod}, F, fullscreen, 1"

          # Toggle floating
          "${mod}, space, togglefloating, active"

          # TODO:
          # Splitting
          # Resizing mods + sizes
          # Parent container selection
          # Media keys
          # Laptop lid
          # Passthrough mode
          # Title-based floating rules
          # Picture-in-Picture rules
          # Idle inhibit
          # Monitor directions & sizes
          # Background
          # Theme
        ];
      };
    };

    services = {
      # Notifications
      mako = {
        enable = mkDefault isLinux;
        extraConfig = readFile (config.scheme inputs.base16-mako);
      };
    };
  };
}
