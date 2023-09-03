{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  ...
}:
with lib; {
  config = mkIf config.graphical.enable {
    programs = {
      # System bar
      waybar = {
        enable = mkDefault isLinux;

        # https://github.com/Alexays/Waybar/wiki/Configuration
        # Number formatting: https://fmt.dev/latest/syntax.html#format-specification-mini-language
        settings = {
          # TODO: use program paths
          mainBar = {
            backlight = {
              format = "{icon} {percent}%";
              format-icons = [
                "󰃞"
                "󰃟"
                "󰃠"
              ];

              on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl -c backlight set 1%-";
              on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl -c backlight set +1%";
            };

            battery = {
              format = "{icon}  {capacity}%";
              format-charging = "󰃨 {capacity}%";
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
              format = "󰥔 {:%H:%M:%S}";
              format-alt = "󰃭 {:%e %b %Y}";
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
              format = "󰉋 ";
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
              on-click = "exec ${pkgs.callPackage ./power.nix {}}/bin/power.sh";
              tooltip = false;
            };

            "custom/displays" = {
              format = "󰍹 ";
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
              format = "󰋊 {percentage_used}%";
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
              "network#vpn"
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
              format-ethernet = " {ifname} 󰓢 {bandwidthTotalBytes:>0}";
              format-wifi = "  {essid} 󰓢 {bandwidthTotalBytes:>0}";
              interval = 1;
              on-click = "alacritty -e nmtui";
              tooltip-format = "{ifname}: {ipaddr}\n{essid} ({signalStrength}%) \n󰕒 {bandwidthUpBytes:>0} 󰇚 {bandwidthDownBytes:>0}";
            };

            "network#vpn" = {
              format = "󰖂";
              interface = "tailscale0";
              tooltip-format = "{ifname}: {ipaddr}/{cidr}\n󰕒 {bandwidthUpBytes:>2} 󰇚 {bandwidthDownBytes:>2}";
            };

            position = "top";
            pulseaudio = {
              format = "{icon} {volume}%";
              format-bluetooth = "{icon} {volume}%  {format_source}";
              format-bluetooth-muted = "󰆪 {icon}  {format_source}";
              format-icons = {
                car = "";
                default = [""];
                hands-free = "󰙌";
                headphone = "󰋋";
                headset = " 󰋎 ";
                phone = "";
                portable = "";
              };

              format-muted = "󰖁 {format_source}";
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
