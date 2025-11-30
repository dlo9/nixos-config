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

    # Doesn't seem to work well, blocks changes by wdisplays
    # systemd.user.services.wl-distore = {
    #   Unit = {
    #     Description = "Wayland Display Store";
    #     PartOf = "graphical-session.target";
    #   };

    #   Service = {
    #     Environment = [
    #       "RUST_LOG=info"
    #     ];
    #     ExecStart = "${pkgs.dlo9.wl-distore}/bin/wl-distore";
    #   };

    #   Install.WantedBy = ["graphical-session.target"];
    # };

    programs.hyprlock = {
      enable = true;
      settings = {
        "$font" = "NotoSansM Nerd Font Mono";

        animations = {
          enabled = true;
          bezier = "linear, 1, 1, 0, 0";
          animation = [
            "fadeIn, 1, 5, linear"
            "fadeOut, 1, 5, linear"
            "inputFieldDots, 1, 2, linear"
          ];
        };

        background = {
          path = "screenshot";
          blur_passes = 2;
        };

        input-field = {
          size = "20%, 5%";
          outline_thickness = 3;
          inner_color = "rgba(0, 0, 0, 0.0)"; # no fill

          outer_color = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          check_color = "rgba(00ff99ee) rgba(ff6633ee) 120deg";
          fail_color = "rgba(ff6633ee) rgba(ff0066ee) 40deg";

          font_color = "rgb(143, 143, 143)";
          fade_on_empty = false;
          rounding = 15;

          font_family = "$font";
          placeholder_text = "Input password...";
          fail_text = "$PAMFAIL";

          dots_spacing = 0.3;

          # uncomment to use an input indicator that does not show the password length (similar to swaylock's input indicator)
          # hide_input = true;

          position = "0, -20";
          halign = "center";
          valign = "center";
        };

        label = [
          {
            # Time
            text = "$TIME";
            font_size = 90;
            font_family = "$font";

            position = "0, 100";
            halign = "center";
            valign = "center";
          }
          {
            # Date
            text = "cmd[update:60000] date +\"%A, %d %B %Y\"";
            font_size = 25;
            font_family = "$font";

            position = "0, 180";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };

    programs.fish.loginShellInit = optionalString config.wayland.windowManager.hyprland.enable ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]
        exec Hyprland
      end
    '';

    xdg = {
      enable = mkDefault true;

      portal = {
        enable = true;

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

        ################################
        ##### Wofi (notifications) #####
        ################################

        "wofi/config".text = ''
          hide_scroll=true
          show=drun
          width=25%
          lines=10
          line_wrap=word
          term=alacritty
          allow_markup=true
          always_parse_args=true
          show_all=true
          print_command=true
          layer=overlay
          allow_images=true
          insensitive=true
          prompt=
          image_size=15
          display_generic=true
          location=center
        '';

        "wofi/config.power".text = ''
          hide_search=true
          hide_scroll=true
          show=dmenu
          width=100
          lines=4
          location=top_right
          x=-120
          y=10
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
          extend_border_grab_area = 50;
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

        gesture = [
          "3, horizontal, workspace" # 3-finger swipe to change workspaces
          "3, vertical, fullscreen, maximize"
        ];

        animation = "global,1,5,default"; # Faster animations

        # Monitors
        monitor = [
          # PiKVM
          "desc:The Linux Foundation PiKVM CAFEBABE, 1920x1080@24, auto, 1"

          # Display Stub Adapter
          "desc:AOC 28E850, 2560x1440@24Hz, auto, 1"

          # Top Left (Anker display adapter)
          "desc:Digital Projection Limited, preferred, 0x0, 1"

          # Top Right
          "desc:HYC CO. LTD. HDMI, preferred, 2560x0, 1"

          # Laptop
          "desc:LG Display 0x062F, preferred, 1600x1440, 1"

          # Default
          ", preferred, auto, 1"
        ];

        # monitorv2 = [
        #   {
        #     # PiKVM
        #     output = "desc:The Linux Foundation PiKVM CAFEBABE";
        #     mode = "1920x1080@24";
        #     position = "auto";
        #   }
        #   {
        #     # Display Stub Adapter
        #     output = "desc:AOC 28E850";
        #     mode = "2560x1440@24Hz";
        #     position = "auto";
        #   }
        #   {
        #     # Top Left (Anker display adapter)
        #     output = "desc:Digital Projection Limited";
        #     mode = "preferred";
        #     position = "0x0";
        #   }
        #   {
        #     # Top Right
        #     output = "desc:HYC CO. LTD. HDMI";
        #     mode = "preferred";
        #     position = "2560x0";
        #   }
        #   {
        #     # Laptop
        #     output = "desc:LG Display 0x062F";
        #     mode = "preferred";
        #     position = "1600x1440";
        #   }
        #   {
        #     # Default
        #     mode = "preferred";
        #     position = "auto";
        #   }
        # ];

        # Keybindings
        bind = let
          toggle-setting = "${pkgs.writeShellApplication {
            name = "toggle-setting";

            text = ''
              #!/bin/sh
              set -e

              if [[ $# -ne 1 ]]; then
                echo "Usage: toggle-setting <option>"
                exit 1
              fi

              hyprctl keyword "$1" "$(hyprctl getoption "$1" | awk 'NR==1 {print xor(1,$2)}')"
            '';
          }}/bin/toggle-setting";
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
          "${mod} + SHIFT, L, exec, ${config.programs.hyprlock.package}/bin/hyprlock"

          # Toggle dimming
          "${mod} + SHIFT, D, exec, ${toggle-setting} decoration:dim_inactive"

          # Move focus
          "${mod}, left, movefocus, l"
          "${mod}, right, movefocus, r"
          "${mod}, up, movefocus, u"
          "${mod}, down, movefocus, d"

          "${mod} + SHIFT, left, movewindow, l"
          "${mod} + SHIFT, right, movewindow, r"
          "${mod} + SHIFT, up, movewindow, u"
          "${mod} + SHIFT, down, movewindow, d"

          "${mod} + CTRL, left, swapwindow, l"
          "${mod} + CTRL, right, swapwindow, r"
          "${mod} + CTRL, up, swapwindow, u"
          "${mod} + CTRL, down, swapwindow, d"

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
          ", switch:Lid Switch, exec, ${config.programs.hyprlock.package}/bin/hyprlock"
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

          # Tooltip for SweetHome3D
          "nofocus, title:win1"
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

      hypridle = {
        enable = true;

        settings = {
          general = {
            lock_cmd = "${config.programs.hyprlock.package}/bin/hyprlock";
            before_sleep_cmd = "${config.programs.hyprlock.package}/bin/hyprlock";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };

          listener = let
            minToSec = n: n * 60;
          in [
            {
              # Lock the screen after 5 minutes
              timeout = minToSec 5;
              on-timeout = "${config.programs.hyprlock.package}/bin/hyprlock";
            }

            {
              # Screen off after 10 minutes
              timeout = minToSec 10;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on && brightnessctl -r ";
            }

            {
              # Suspend after 15 minutes
              timeout = minToSec 15;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };
    };
  };
}
