{ config, pkgs, lib, inputs, sysCfg, ... }:

with lib;
with types;
with builtins;

let
  cfg = config.home.gui.sway.waybar;
in
{
  options.home.gui.sway.waybar = {
    enable = mkEnableOption "waybar" // { default = sysCfg.graphical.enable; };
  };

  config = mkIf cfg.enable {
    programs = {
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

              on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl -c backlight set 1%-";
              on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl -c backlight set +1%";
            };

            battery = {
              format = "{icon}  {capacity}%";
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
              on-click = "exec ${pkgs.wofi}/bin/wofi -c ~/.config/wofi/config -I";
              tooltip = false;
            };

            "custom/power" = {
              format = "⏻";
              on-click = "exec ${pkgs.callPackage ./power.nix {}}";
              tooltip = false;
            };

            "custom/displays" = {
              format = " ";
              on-click = "exec ${pkgs.wdisplays}/bin/wdisplays";
              tooltip = false;
            };

            "custom/terminal" = {
              format = " ";
              on-click = "exec alacritty";
              tooltip = false;
            };

            "custom/weather" = {
              exec = "${pkgs.writeScript "weather.sh" (readFile ./weather.sh)} 'Vancouver,WA'";
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
              "custom/displays"
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
              on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
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

          ${readFile (config.scheme inputs.base16-waybar)}

          ${readFile ./bar.css}
        '';
      };
    };
  };
}
