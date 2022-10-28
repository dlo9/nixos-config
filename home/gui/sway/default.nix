{ config, pkgs, lib, inputs, sysCfg, ... }:

with lib;
with types;
with builtins;

let
  cfg = config.home.gui.sway;

  wallpaper = fetchurl {
    # Spaceman
    # https://forum.endeavouros.com/t/new-wallpaper/6308/162
    url = https://forum.endeavouros.com/uploads/default/original/3X/c/d/cdb27eeb063270f9529fae6e87e16fa350bed357.jpeg;
    sha256 = "02b892xxwyzzl2xyracnjhhvxvyya4qkwpaq7skn7blg51n56yz2";

    # Pink sunset
    # url = https://cutewallpaper.org/22/retro-neon-race-4k-wallpapers/285729412.jpg;
    # sha256 = "";
  };
in
{
  imports = [
    ./bar
  ];

  options.home.gui.sway = {
    enable = mkEnableOption "sway window manager" // { default = sysCfg.graphical.enable; };
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      # Clipboard
      wl-clipboard
    ];

    programs = {
      # Notifications
      mako = {
        enable = true;
        extraConfig = (readFile (config.scheme inputs.base16-mako));
      };

      swaylock.settings = with config.scheme.withHashtag; let
        # https://github.com/Misterio77/dotfiles/blob/sway/home/.config/sway/swaylock.sh
        insideColor = base01;
        ringColor = base02;
        errorColor = base08;
        clearedColor = base0C;
        highlightColor = base0B;
        verifyingColor = base09;
        textColor = base07;
      in
      {
        indicator-caps-lock = true;
        image = "${wallpaper}";
        scaling = "fill";
        font = "NotoSansMono Nerd Font";
        font-size = 20;
        indicator-radius = 115;

        ring-color = ringColor;
        inside-wrong-color = errorColor;
        ring-wrong-color = errorColor;
        key-hl-color = highlightColor;
        bs-hl-color = errorColor;
        ring-ver-color = verifyingColor;
        inside-ver-color = verifyingColor;
        inside-color = insideColor;
        text-color = textColor;
        text-clear-color = insideColor;
        text-ver-color = insideColor;
        text-wrong-color = insideColor;
        text-caps-lock-color = insideColor;
        inside-clear-color = clearedColor;
        ring-clear-color = clearedColor;
        inside-caps-lock-color = verifyingColor;
        ring-caps-lock-color = ringColor;
        separator-color = ringColor;
      };
    };

    xdg = {
      enable = true;

      configFile = {
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

        "wofi/style.css".text = ''
          *{
            font-family: NotoSansMono Nerd Font;
            font-size: 14px;
          }

          window {
            border: 1px solid;
          }

          #input {
            margin-bottom: 15px;
            padding:3px;
            border-radius: 5px;
            border:none;
          }

          #outer-box {
            margin: 5px;
            padding:15px;
          }

          #text {
            padding: 5px;
          }

          ${readFile (config.scheme inputs.base16-wofi)}
        '';

        "wofi/style.widgets.css".text = ''
          *{
            font-family: NotoSansMono Nerd Font;
            font-size: 14px;
          }

          #window {
            border: 1px solid white;
            margin: 0px 5px 0px 5px;
          }

          #outer-box {
            margin: 5px;
            padding:10px;
            margin-top: -22px;
          }

          #text {
            padding: 5px;
            color: white;
          }

          ${readFile (config.scheme inputs.base16-wofi)}
        '';
      };
    };

    services = {
      # Idle config for sway
      #   - 5m: lock the screen
      #   - 10m: turn off the screen
      #   - 15m: suspend
      swayidle =
        let
          swaylock = "${pkgs.swaylock}/bin/swaylock";
          swaymsg = "${pkgs.sway}/bin/swaymsg";
        in
        {
          enable = true;

          timeouts = [
            { timeout = 5 * 60; command = "${swaylock} -f"; }
            { timeout = 10 * 60; command = ''${swaymsg} "output * dpms off"''; resumeCommand = ''${swaymsg} "output * dpms on"''; }
            { timeout = 15 * 60; command = "systemctl suspend"; }
          ];

          events = [
            { event = "before-sleep"; command = "${swaylock}"; }
            { event = "lock"; command = "${swaylock}"; }
          ];
        };
    };

    # Mod1 = Alt
    wayland.windowManager.sway =
      let
        modifier = "Mod1";
      in
      {
        enable = true;

        xwayland = true;

        wrapperFeatures = {
          base = true;
          gtk = true;
        };

        config = with config.scheme.withHashtag; rec {
          colors = {
            background = base07;
            focused = { border = base05; background = base0D; text = base00; indicator = base0D; childBorder = base0D; };
            focusedInactive = { border = base01; background = base01; text = base05; indicator = base03; childBorder = base01; };
            placeholder = { border = base00; background = base00; text = base05; indicator = base00; childBorder = base00; };
            unfocused = { border = base01; background = base00; text = base05; indicator = base01; childBorder = base01; };
            urgent = { border = base08; background = base08; text = base00; indicator = base08; childBorder = base08; };
          };

          bars = [
            {
              command = "${config.programs.waybar.package}/bin/waybar";
              colors = {
                background = base00;
                separator = base01;
                statusline = base04;

                focusedWorkspace = { border = base05; background = base0D; text = base00; };
                activeWorkspace = { border = base05; background = base03; text = base00; };
                inactiveWorkspace = { border = base03; background = base01; text = base05; };
                urgentWorkspace = { border = base08; background = base08; text = base00; };
                bindingMode = { border = base00; background = base0A; text = base00; };
              };
            }
          ];

          fonts = {
            names = [ "NotoSansMono Nerd Font" ];
            style = "Regular";
            size = 11.0;
          };

          gaps = {
            inner = 10;
            outer = 0;
            smartBorders = "on";
          };

          floating.border = 1;
          window.border = 1;

          # See available outputs with: swaymsg -t get_outputs
          output = {
            "*" = { bg = "${wallpaper} fill"; };
            HEADLESS-1 = { resolution = "1920x1080"; position = "0,0"; };
            HDMI-A-1 = { resolution = "1280x720"; position = "0,0"; };

            # Left monitor
            DP-1 = { resolution = "2560x1400"; position = "0,0"; };
            DP-3 = { resolution = "2560x1400"; position = "0,0"; };

            # Right monitor
            DVI-D-1 = { resolution = "2560x1400"; position = "2560,0"; };
            #HDMI-A-1 = { resolution = "2560x1400"; position = "2560,0"; };
          };

          workspaceOutputAssign = [
            { output = "*"; workspace = "1"; }

            # Left monitor
            { output = "DP-1"; workspace = "1"; }
            { output = "DP-3"; workspace = "1"; }

            # Right monitor
            { output = "DVI-D-1"; workspace = "10"; }
            { output = "HDMI-A-1"; workspace = "10"; }
          ];

          # See available inputs with: swaymsg -t get_inputs
          input = {
            "type:touchpad" = { dwt = "enabled"; tap = "enabled"; natural_scroll = "disabled"; };
            "type:keyboard" = { xkb_layout = "us"; };
          };

          window.commands = [
            {
              criteria = { shell = "xdg_shell"; };
              command = ''title_format "%title (%app_id)"'';
            }

            {
              criteria = { shell = "x_wayland"; };
              command = ''title_format "%class - %title"'';
            }

            # Network manager
            {
              criteria = { title = "nmtui"; };
              command = "floating enable, resize set width 50 ppt height 70 ppt";
            }

            # Performance monitoring
            {
              criteria = { title = "htop"; };
              command = "floating enable, resize set width 50 ppt height 70 ppt";
            }

            # Inhibit idle
            {
              criteria = { app_id = "firefox"; };
              command = "inhibit_idle fullscreen";
            }

            {
              criteria = { app_id = "Chromium"; };
              command = "inhibit_idle fullscreen";
            }

            # Copy progress
            {
              criteria = { title = "File Operation Progress"; };
              command = "{
                floating enable
                sticky enable
                border pixel 1
                resize set width 40 ppt height 30 ppt
              }";
            }

            # Picture-in-Picture: Shrink window to 1/16th workspace size, in bottom right corner
            {
              criteria = { title = "Picture-in-Picture"; };
              command = "{
                floating enable
                sticky enable
                resize set width 25 ppt height 25 ppt
                move position 75 ppt 75 ppt
              }";
            }

            {
              criteria = { title = "Tree Style Tab"; };
              command = "floating enable, resize set 25 ppt 25 ppt";
            }

            # Sound control
            {
              criteria = { app_id = "pavucontrol"; };
              command = "floating enable, resize set width 40 ppt height 30 ppt";
            }

            # Floating windows
            { criteria = { window_role = "pop-up"; }; command = "floating enable"; }
            { criteria = { window_role = "bubble"; }; command = "floating enable"; }
            { criteria = { window_role = "task_dialog"; }; command = "floating enable"; }
            { criteria = { window_role = "Preferences"; }; command = "floating enable"; }
            { criteria = { window_role = "About"; }; command = "floating enable"; }
            { criteria = { window_type = "dialog"; }; command = "floating enable"; }
            { criteria = { window_type = "menu"; }; command = "floating enable"; }
            { criteria = { title = "Save File"; }; command = "floating enable"; }
            { criteria = { app_id = "yad"; }; command = "floating enable"; } # Dialogs
          ];

          ####################
          ##### Controls #####
          ####################

          inherit modifier;
          terminal = "alacritty";
          menu = "${pkgs.wofi}/bin/wofi -c ~/.config/wofi/config -I";

          keybindings = lib.mkOptionDefault {
            # Open terminal
            "${modifier}+Return" = "exec ${terminal}";

            # Open the power menu
            "${modifier}+Shift+e" = "exec ${pkgs.callPackage ./bar/power.nix {}}/bin/power.sh";

            # Kill focused window
            "${modifier}+Shift+q" = "kill";

            # Start the application launcher
            "${modifier}+d" = "exec ${menu}";

            # Reload
            "${modifier}+Shift+r" = "reload";

            # Lock
            "${modifier}+l" = "exec ${pkgs.swaylock}/bin/swaylock";

            ##### Moving around #####
            "${modifier}+Left" = "focus left";
            "${modifier}+Down" = "focus down";
            "${modifier}+Up" = "focus up";
            "${modifier}+Right" = "focus right";

            "${modifier}+Shift+Left" = "move left";
            "${modifier}+Shift+Down" = "move down";
            "${modifier}+Shift+Up" = "move up";
            "${modifier}+Shift+Right" = "move right";

            ##### Workspaces #####
            "${modifier}+1" = "workspace number 1";
            "${modifier}+2" = "workspace number 2";
            "${modifier}+3" = "workspace number 3";
            "${modifier}+4" = "workspace number 4";
            "${modifier}+5" = "workspace number 5";
            "${modifier}+6" = "workspace number 6";
            "${modifier}+7" = "workspace number 7";
            "${modifier}+8" = "workspace number 8";
            "${modifier}+9" = "workspace number 9";
            "${modifier}+0" = "workspace number 10";

            "${modifier}+Shift+1" = "move container to workspace number 1";
            "${modifier}+Shift+2" = "move container to workspace number 2";
            "${modifier}+Shift+3" = "move container to workspace number 3";
            "${modifier}+Shift+4" = "move container to workspace number 4";
            "${modifier}+Shift+5" = "move container to workspace number 5";
            "${modifier}+Shift+6" = "move container to workspace number 6";
            "${modifier}+Shift+7" = "move container to workspace number 7";
            "${modifier}+Shift+8" = "move container to workspace number 8";
            "${modifier}+Shift+9" = "move container to workspace number 9";
            "${modifier}+Shift+0" = "move container to workspace number 10";

            ##### Layout #####
            "${modifier}+h" = "splith";
            "${modifier}+v" = "splitv";

            "${modifier}+s" = "layout stacking";
            "${modifier}+w" = "layout tabbed";
            "${modifier}+e" = "layout toggle split";

            "${modifier}+f" = "fullscreen";
            "${modifier}+Shift+space" = "floating toggle"; # Toggle the current focus between tiling and floating mode
            "${modifier}+space" = "focus mode_toggle"; # Swap focus between the tiling area and the floating area
            "${modifier}+a" = "focus parent"; # Move focus to the parent container

            ##### Scratchpad #####

            # Sway has a "scratchpad", which is a bag of holding for windows.
            # You can send windows there and get them back later.

            # Move the currently focused window to the scratchpad
            "${modifier}+Shift+minus" = "move scratchpad";

            # Show the next scratchpad window or hide the focused scratchpad window.
            # If there are multiple scratchpad windows, this command cycles through them.
            "${modifier}+minus" = "scratchpad show";

            ######################
            ##### Media keys #####
            ######################

            # TODO: use real application paths
            "--locked XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +2%";
            "--locked XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -2%";
            "--locked XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "--locked XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";

            "--locked XF86AudioPlay" = "exec playerctl play";
            "--locked XF86AudioPause" = "exec playerctl pause";
            "--locked XF86AudioNext" = "exec playerctl next";
            "--locked XF86AudioPrev" = "exec playerctl previous";

            "--locked XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl -c backlight set +2%";
            "--locked XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl -c backlight set 2%-";

            ###############################
            ##### Resizing containers #####
            ###############################

            "${modifier}+r" = ''mode "resize"'';

            # Resize floating windows with mouse scroll:
            "--whole-window --border ${modifier}+button4" = "resize shrink height 5 px or 5 ppt";
            "--whole-window --border ${modifier}+button5" = "resize grow height 5 px or 5 ppt";
            "--whole-window --border ${modifier}+Shift+button4" = "resize shrink width 5 px or 5 ppt";
            "--whole-window --border ${modifier}+Shift+button5" = "resize grow width 5 px or 5 ppt";
          };

          modes = {
            resize = {
              Left = "resize shrink width 10px";
              Down = "resize grow height 10px";
              Up = "resize shrink height 10px";
              Right = "resize grow width 10px";

              Return = ''mode "default"'';
              Escape = ''mode "default"'';
            };
          };

          startup = [
            # Clipboard manager
            { command = "${pkgs.copyq}/bin/copyq"; }

            { command = "polkit-agent"; }

            # Notifications
            { command = "${pkgs.mako}/bin/mako"; }

            # Network Applet
            #{ command = "exec nm-applet --indicator"; }

            # GTK3 applications take a long time to start
            #{ command = "exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK"; }
            #{ command = "exec hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK"; }

            # Search for desktop entries
            { command = "${pkgs.dex}/bin/dex -a -s /etc/xdg/autostart/:~/.config/autostart/"; }

            { command = "novnc-server"; }
          ];
        };

        extraConfig = ''
          # Turn the output on/off when laptop lid is open/closed
          bindswitch --reload --locked lid:on output eDP-1 disable
          bindswitch --reload --locked lid:off output eDP-1 enable

          # Passthrough mode for sway-in-sway or vnc
          # https://man.archlinux.org/man/wayvnc.1.en#FAQ
          bindsym ${modifier}+Tab mode passthrough
          mode passthrough {
            bindsym ${modifier}+Tab mode default
          }
        '';
      };
  };
}
