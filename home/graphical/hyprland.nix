{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  osConfig,
  ...
}:
with lib;
with types;
with builtins; {
  config = mkIf (config.graphical.enable && isLinux) {
    home.packages = with pkgs; [
      hyprpicker
    ];

    programs.fish.loginShellInit = optionalString config.wayland.windowManager.hyprland.enable ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]
        exec Hyprland
      end
    '';

    xdg = {
      enable = mkDefault true;

      portal = {
        enable = false; # Enabled on the system
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];

        configPackages = [config.wayland.windowManager.hyprland.package];
        xdgOpenUsePortal = true;

        config = {
          common.default = ["hyprland" "gtk"];
          preferred.default = ["hyprland" "gtk"];
        };
      };

      configFile = {
        # Set wallpaper
        "hypr/hyprpaper.conf".text = ''
          ipc = off
          preload = ${config.wallpapers.default}
          wallpaper = , ${config.wallpapers.default}
          splash = false
        '';
      };
    };

    # View logs with: `tail -f /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log`
    wayland.windowManager.hyprland = let
      mod = "ALT";
    in {
      enable = mkDefault (!osConfig.services.desktopManager.plasma6.enable);
      plugins = [];

      # https://wiki.hyprland.org/Configuring/Variables/
      settings = let
        wpctl = "${pkgs.wireplumber}/bin/wpctl";
        playerctl = "${pkgs.playerctl}/bin/playerctl";
        brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
      in {
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

        # exec = [
        #   "${pkgs.writeShellApplication {
        #     name = "hypr-ipc";
        #     runtimeInputs = [pkgs.socat];
        #     text = builtins.readFile ./hypr-ipc.sh;
        #   }}/bin/hypr-ipc"
        # ];

        general = {
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(00000000)";
          resize_on_border = true;
          border_size = 2;
        };

        cursor = {
          inactive_timeout = 10;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        decoration = {
          rounding = 5;
          dim_inactive = true;
          dim_strength = 0.4;

          blur = {
            noise = 0.1;
          };
        };

        gestures = {
          workspace_swipe = true; # 3-finger swipe
        };

        animation = "global,1,5,default"; # Faster animations

        # Monitors
        monitor = [
          "desc:The Linux Foundation PiKVM CAFEBABE, 1920x1080@24, auto, 1" # PiKVM
          "desc:AOC 28E850, 2560x1440@24Hz, auto, 1" # Display Stub Adapter
          ", preferred, auto, 1" # Default
          # "DP-1, highres, 0x0, 1"
        ];

        # Keybindings
        bind = [
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
          "${mod} + SHIFT, L, exec, ${pkgs.swaylock}/bin/swaylock"

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
          # Parent container selection
          # Title-based floating rules
          # Picture-in-Picture rules
          # Idle inhibit
          # Monitor directions & sizes
          # Theme
        ];

        # Repeat when held, and works on lock screen
        bindel = [
          # Media keys
          ", XF86AudioRaiseVolume, exec, ${wpctl} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"

          ", XF86MonBrightnessUp, exec, ${brightnessctl} -c backlight set +5%"
          ", XF86MonBrightnessDown, exec, ${brightnessctl} -c backlight set 5%-"
        ];

        # Works on lock screen
        bindl = [
          # Media keys
          ", XF86AudioMute, exec, ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

          ", XF86AudioPlay, exec, ${playerctl} play"
          ", XF86AudioPause, exec, ${playerctl} pause"
          ", XF86AudioNext, exec, ${playerctl} next"
          ", XF86AudioPrev, exec, ${playerctl} previous"

          # Find names with:
          # hyprctl devices -j
          ", switch:Lid Switch, exec, ${pkgs.swaylock}/bin/swaylock"
        ];

        # Window rules
        windowrulev2 = [
          #   "nofullscreenrequest, title:(Tree Style Tab)"
          #   "float, title:(Tree Style Tab)"
          #   "size 10% 10%, title:(Tree Style Tab)"
          #   "center, title:(Tree Style Tab)"
          #   "stayfocused, title:(Tree Style Tab)"
          "bordercolor rgb(ff0000), title:(Tree Style Tab)"

          "opacity 0.8 override, class:Alacritty"
        ];
      };

      extraConfig = ''
        ##################
        ### Reize Mode ###
        ##################

        # Switch to resize mode
        bind=${mod}, R, submap, resize
        submap=resize

        # sets repeatable binds for resizing the active window
        binde=, right, resizeactive, 10 0
        binde=, left, resizeactive, -10 0
        binde=, up, resizeactive, 0 -10
        binde=, down, resizeactive, 0 10

        # Exit resize mode
        bind=, escape, submap, reset
        bind=${mod}, R, submap, reset
        submap=reset

        ########################
        ### Passthrough Mode ###
        ########################

        # Switch to a passthough mode
        bind=${mod}, P, submap, passthrough
        submap=passthrough

        # Exit passthrough mode
        bind=${mod}, escape, submap, reset
        bind=${mod}, P, submap, reset
        submap=reset
      '';
    };

    services = {
      # Notifications
      mako.enable = mkDefault isLinux;
    };
  };
}
