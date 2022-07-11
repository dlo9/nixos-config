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
in
{
  options.home.gui = {
    enable = mkEnableOption "user graphical programs" // { default = true; };
  };

  config = mkIf cfg.enable {
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
        #################################
        ##### Sway (window manager) #####
        #################################

        sway.source = ./sway;
        swaylock.source = ./swaylock;

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
      gammastep = {
        enable = true;
        provider = "geoclue2";
        tray = true;
      };

      syncthing.enable = true;
    };
  };
}
