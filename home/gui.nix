# Home manager configuration
# - Manual: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
# - Config: https://rycee.gitlab.io/home-manager/options.html

{ config, pkgs, lib, inputs, sysCfg, ... }:

with lib;
with types;

let
  cfg = config.home.gui;

  weather-module = pkgs.writeScript "wofi-weather.sh" ''
    #!/bin/sh
    # Format options: https://github.com/chubin/wttr.in

    LOCATION="$1"
    WEATHER="$(curl -s "wttr.in/$LOCATION?format=%l|%c|%C|%t|%f|%w" | sed -r -e 's/\s*\|\s*/|/g' -e 's/\+([0-9.]+°)/\1/g')"
    LOCATION=$(echo "$WEATHER" | awk -F '|' '{print $1}' | sed 's/,/, /g')
    ICON=$(echo "$WEATHER" | awk -F '|' '{print $2}')
    DESCRIPTION=$(echo "$WEATHER" | awk -F '|' '{print $3}')
    TEMP=$(echo "$WEATHER" | awk -F '|' '{print $4}')
    FEELS_LIKE=$(echo "$WEATHER" | awk -F '|' '{print $5}')
    WIND=$(echo "$WEATHER" | awk -F '|' '{print $6}')

    printf '{"text":"%s %s", "tooltip":"%s: %s, %s, %s", "class":"", "percentage":""}' "$ICON" "$FEELS_LIKE" "$LOCATION" "$DESCRIPTION" "$TEMP" "$WIND"
  '';

  power-module = pkgs.writeScript "power-menu.sh" ''
    #!/bin/sh

    entries="Logout Suspend Reboot Shutdown"

    selected=$(printf '%s\n' $entries | wofi --conf=$HOME/.config/wofi/config.power --style=$HOME/.config/wofi/style.widgets.css | awk '{print tolower($1)}')

    case $selected in
      logout)
        swaymsg exit;;
      suspend)
        exec systemctl suspend;;
      reboot)
        exec systemctl reboot;;
      shutdown)
        exec systemctl poweroff -i;;
    esac
  '';

  wallpaper = builtins.fetchurl {
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
  options.home.gui = {
    enable = mkEnableOption "user graphical programs" // { default = true; };
  };

  config = mkIf cfg.enable {

    home.pointerCursor = {
      name = "Numix-Cursor-Light";
      package = pkgs.numix-cursor-theme;
    };

    programs = {
      qutebrowser.enable = true;

      vim.plugins = with pkgs.vimPlugins // sysCfg.pkgs.vimPlugins; [
        # Fix copy to system clipboard on wayland
        vim-wayland-clipboard
      ];

      alacritty = {
        enable = true;

        # https://github.com/alacritty/alacritty/blob/master/alacritty.yml
        settings = {
          window.opacity = 0.9;
          decorations = "full";
          font = {
            normal.family = "NotoSansMono Nerd Font";
            #size = 11;
          };

          save_to_clipboard = true;
          cursor.style = {
            shape = "Block";
            blinking = "Always";
            shell = {
              program = config.programs.fish.package;
              args = [ "--login" ];
            };
          };

          mouse.hide_when_typing = false;
        } // (sysCfg.lib.fromYAML (config.scheme inputs.base16-alacritty));
      };

      # Notifications
      mako = {
        enable = true;
        extraConfig = (builtins.readFile (config.scheme inputs.base16-mako));
      };

      # System bar
      waybar = {
        enable = true;
        settings = {
          # TODO: use program paths
          mainBar = {
            backlight = {
              format = "{icon} {percent}%";
              format-icons = [
                ""
                ""
                ""
              ];

              on-scroll-down = "brightnessctl -c backlight set 1%-";
              on-scroll-up = "brightnessctl -c backlight set +1%";
            };

            battery = {
              format = "{icon} {capacity}%";
              format-charging = " {capacity}%";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];

              format-plugged = " {capacity}%";
              states = {
                critical = 15;
                warning = 30;
              };
            };

            clock = {
              format = " {:%H:%M:%S}";
              format-alt = " {:%e %b %Y}";
              interval = 1;
              tooltip-format = "{:%H:%M:%S, %a, %B %d, %Y}";
            };

            cpu = {
              format = " {usage:2}%";
              interval = 5;
              on-click = "alactritty -e htop";
              states = {
                critical = 90;
                warning = 70;
              };
            };

            "custom/files" = {
              format = " ";
              on-click = "exec thunar";
              tooltip = false;
            };

            "custom/firefox" = {
              format = " ";
              on-click = "exec firefox";
              tooltip = false;
            };

            "custom/launcher" = {
              format = " ";
              on-click = "exec wofi -c ~/.config/wofi/config -I";
              tooltip = false;
            };

            "custom/power" = {
              format = "⏻";
              on-click = "exec ${power-module}";
              tooltip = false;
            };

            "custom/terminal" = {
              format = " ";
              on-click = "exec alacritty";
              tooltip = false;
            };

            "custom/weather" = {
              exec = "${weather-module} 'Vancouver,WA'";
              interval = 600;
              return-type = "json";
            };

            disk = {
              format = " {percentage_used}%";
              interval = 5;
              on-click = "alactritty -e 'df -h'";
              path = "/";
              states = {
                critical = 90;
                warning = 70;
              };

              tooltip-format = "Used: {used} ({percentage_used}%)\nFree: {free} ({percentage_free}%)\nTotal: {total}";
            };

            layer = "top";
            memory = {
              format = " {}%";
              interval = 5;
              on-click = "alacritty -e htop";
              states = {
                critical = 90;
                warning = 70;
              };
            };

            modules-center = [
              "clock"
              "custom/weather"
            ];

            modules-left = [
              "custom/launcher"
              "sway/workspaces"
              "sway/mode"
            ];

            modules-right = [
              "network"
              "memory"
              "cpu"
              "disk"
              "pulseaudio"
              "battery"
              "backlight"
              "temperature"
              "tray"
              "custom/power"
            ];

            network = {
              format-disconnected = "⚠ Disconnected";
              format-ethernet = " {ifname}";
              format-wifi = " {signalStrength}%";
              interval = 1;
              on-click = "alacritty -e nmtui";
              tooltip-format = "{ifname}: {ipaddr}\n{essid}\n祝 {bandwidthUpBits:>8}  {bandwidthDownBits:>8}";
            };

            "network#vpn" = {
              format = " {essid} ({signalStrength}%)";
              format-disconnected = "⚠ Disconnected";
              interface = "tun0";
              tooltip-format = "{ifname}: {ipaddr}/{cidr}";
            };

            position = "top";
            pulseaudio = {
              format = "{icon} {volume}%";
              format-bluetooth = "{icon} {volume}%  {format_source}";
              format-bluetooth-muted = " {icon}  {format_source}";
              format-icons = {
                car = "";
                default = [ "" ];
                hands-free = "וֹ";
                headphone = "";
                headset = "  ";
                phone = "";
                portable = "";
              };

              format-muted = "婢 {format_source}";
              format-source = "{volume}% ";
              format-source-muted = "";
              on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
              on-click-right = "pavucontrol";
              scroll-step = 1;
            };

            "sway/mode" = {
              format = "{}";
              tooltip = false;
            };

            "sway/window" = {
              format = "{}";
              max-length = 120;
            };

            "sway/workspaces" = {
              all-outputs = false;
              disable-markup = false;
              disable-scroll = true;
              format = " {icon} ";
            };

            tray = {
              icon-size = 18;
              spacing = 10;
            };
          };
        };

        style = ''
          /*****************/
          /***** Theme *****/
          /*****************/

          @import "${config.scheme inputs.base16-waybar}";

          /**********************/
          /***** Global/Bar *****/
          /**********************/

          * {
            font-family: NotoSansMono Nerd Font;
            font-size: 14px;

            /* Slanted */
            border-radius: 0.3em 0.9em;

            /* None */
            /*border-radius: 0;*/

            outline: none;
            border-color: transparent;
          }

          #waybar {
            background: @base00;
          }

          label {
            padding: 0 0.5em;
            margin: 0.3em;
            color: @base05;
          }

          /************************/
          /***** Left modules *****/
          /************************/

          /* Use button padding instead of label */
          #workspaces label {
            padding: 0;
            margin: 0;
          }

          #workspaces button {
            padding: 0;
            margin: 0.3em 0.2em;
          }

          /* Workspace highlighting */

          /* Plain and translucent by default */
          #workspaces button {
            box-shadow: 0 -0.2em alpha(@base04, 0.5);
            background: alpha(@base04, 0.25);
          }

          /* More opaque when hovered */
          #workspaces :hover {
            box-shadow: 0 -0.2em @base04;
            background: alpha(@base04, 0.5);
          }

          /* Change color when focused */
          #workspaces .focused {
            box-shadow: 0 -0.2em alpha(@base0F, 0.75);
            background: alpha(@base0F, 0.25);
          }

          /* Change color and more opaque when both */
          #workspaces :hover.focused {
            box-shadow: 0 -0.2em @base0F;
            background: alpha(@base0F, 0.5);
          }

          /**************************/
          /***** Center modules *****/
          /**************************/

          /* Center weather icon*/

          #custom-weather {
            margin-left: -0.5em;
            margin-right: 3em;
          }

          /*************************/
          /***** Right modules *****/
          /*************************/

          /* Module backgrounds */
          #network {
            box-shadow: 0 -0.2em @base0F;
            background: alpha(@base0F, 0.25);
          }

          #memory {
            box-shadow: 0 -0.2em @base08;
            background: alpha(@base08, 0.25);
          }

          #cpu {
            box-shadow: 0 -0.2em @base0A;
            background: alpha(@base0A, 0.25);
          }

          #disk {
            box-shadow: 0 -0.2em @base0D;
            background: alpha(@base0D, 0.25);
          }

          #pulseaudio {
            box-shadow: 0 -0.2em @base0C;
            background: alpha(@base0C, 0.25);
          }

          #battery {
            box-shadow: 0 -0.2em @base0B;
            background: alpha(@base0B, 0.25);
          }

          #backlight {
            box-shadow: 0 -0.2em @base06;
            background: alpha(@base06, 0.25);
          }

          #temperature {
            box-shadow: 0 -0.2em @base09;
            background: alpha(@base09, 0.25);
          }

          #tray {
            padding: 0 0.5em;
            margin: 0.3em 0.2em;

            box-shadow: 0 -0.2em @base0E;
            background: alpha(@base0E, 0.25);
          }

          /* Fix tooltip background */
          tooltip, tooltip label {
            background: @base02;
          }
        '';
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

      vscode = {
        enable = true;

        # Necessary for extensions for now
        # https://github.com/nix-community/home-manager/issues/2798
        mutableExtensionsDir = true;

        extensions = with pkgs.vscode-extensions // sysCfg.pkgs.vscode-extensions; [
          shan.code-settings-sync
          jnoortheen.nix-ide
        ];
      };
    };

    xdg = {
      enable = true;

      # Default applications
      mimeApps = {
        enable = true;

        defaultApplications = {
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
        };
      };

      configFile = {
        ################################
        ##### Wofi (notifications) #####
        ################################

        wofi = {
          # Needs to be recursive so that styles below can be written
          recursive = true;
          source = ./wofi;
        };

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

          ${builtins.readFile (config.scheme inputs.base16-wofi)}
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

          ${builtins.readFile (config.scheme inputs.base16-wofi)}
        '';
      };
    };

    gtk = {
      enable = true;

      iconTheme = {
        #package = pkgs.vimix-icon-theme;
        #name = "Vimix";

        name = "Flat-Remix-Teal-Dark";
        package = pkgs.flat-remix-icon-theme;
      };

      theme = {
        #package = pkgs.vimix-gtk-themes;

        name = "FlatColor-base16";
        package =
          let
            gtk2-theme = config.scheme {
              templateRepo = inputs.base16-gtk;
              target = "gtk-2";
            };

            gtk3-theme = config.scheme {
              templateRepo = inputs.base16-gtk;
              target = "gtk-3";
            };
          in
          sysCfg.pkgs.flatcolor-gtk-theme.overrideAttrs (oldAttrs: {
            # Build instructions: https://github.com/Misterio77/base16-gtk-flatcolor
            # This builds, but doesn't seem to work very well?
            postInstall = ''
              # Base theme info
              base_theme=FlatColor
              base_theme_path="$out/share/themes/$base_theme"

              new_theme="$base_theme-base16"
              new_theme_path="$out/share/themes/$new_theme"

              # Clone and rename theme
              cp -r "$base_theme_path" "$new_theme_path"
              grep -Rl "$base_theme" "$new_theme_path" | xargs -n1 sed -i "s/$base_theme/$new_theme/"

              # Rewrite colors into theme files
              # This is specific to FlatColor, since gtk themes dont standarize base color variables
              printf "%s\n" 'include "${gtk2-theme}"' "$(sed -E '/.*#[a-fA-F0-9]{6}.*/d' "$base_theme_path/gtk-2.0/gtkrc")" > "$new_theme_path/gtk-2.0/gtkrc"
              printf "%s\n" '@import url("${gtk3-theme}");' "$(sed '1,10d' "$base_theme_path/gtk-3.0/gtk.css")" > "$new_theme_path/gtk-3.0/gtk.css"
              printf "%s\n" '@import url("${gtk3-theme}");' "$(sed '1,26d' "$base_theme_path/gtk-3.20/gtk.css")" > "$new_theme_path/gtk-3.20/gtk.css"
            '';
          });
      };
    };

    home.packages = with pkgs // sysCfg.pkgs; [
      # For debugging themes
      lxappearance-xwayland

      # So that links open in a browser when clicked from other applications
      # (e.g. vscode)
      xdg-utils
    ];

    services = {
      # Bluetooth controls
      blueman-applet.enable = true;

      # Enable red-shifted nightime display
      gammastep = {
        enable = true;
        provider = "geoclue2";
        tray = true;
      };

      # File syncing
      syncthing.enable = true;

      # Idle config for sway
      #   - 5m: lock the screen
      #   - 10m: turn off the screen
      #   - 15m: suspend
      swayidle = {
        enable = true;

        timeouts = [
          { timeout = 5 * 60; command = "swaylock -f"; }
          { timeout = 10 * 60; command = ''swaymsg "output * dpms off"''; resumeCommand = ''swaymsg "output * dpms on"''; }
          { timeout = 15 * 60; command = "systemctl suspend"; }
        ];

        events = [
          { event = "before-sleep"; command = "swaylock"; }
          { event = "lock"; command = "swaylock"; }
        ];
      };
    };

    wayland.windowManager.sway = {
      enable = true;
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
            command = "${pkgs.waybar}/bin/waybar";
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
          DP-1 = { resolution = "2560x1400"; position = "0,0"; };
          DVI-D-1 = { resolution = "2560x1400"; position = "2560,0"; };
        };

        workspaceOutputAssign = [
          { output = "*"; workspace = "1"; }
          { output = "DP-1"; workspace = "1"; }
          { output = "DVI-D-1"; workspace = "10"; }
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

        modifier = "Mod1"; # Alt
        terminal = "alacritty";
        menu = "wofi -c ~/.config/wofi/config -I";

        keybindings = lib.mkOptionDefault {
          # Open terminal
          "${modifier}+Return" = "exec ${terminal}";

          # Open the power menu
          "${modifier}+Shift+e" = "exec ${power-module}";

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

          "--locked XF86MonBrightnessUp" = "exec brightnessctl -c backlight set +2%";
          "--locked XF86MonBrightnessDown" = "exec brightnessctl -c backlight set 2%-";

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
          { command = "exec polkit-agent"; }
          { command = "exec mako"; } # Notifications
          #{ command = "exec nm-applet --indicator"; } # Network Applet

          # GTK3 applications take a long time to start
          #{ command = "exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK"; }
          #{ command = "exec hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK"; }

          # Search for desktop entries
          { command = "exec dex -a -s /etc/xdg/autostart/:~/.config/autostart/"; }
        ];
      };

      extraConfig = ''
        # Turn the output on/off when laptop lid is open/closed
        bindswitch --reload --locked lid:on output eDP-1 disable
        bindswitch --reload --locked lid:off output eDP-1 enable
      '';
    };
  };
}
