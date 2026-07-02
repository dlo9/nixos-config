{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  ...
}:
with lib; let
  # Hyprland's Lua config rejects the classic string-based IPC dispatch that
  # waybar's native hyprland/workspaces module uses to switch workspaces
  # (https://github.com/Alexays/waybar/issues/5008). Until that's fixed
  # upstream, render each workspace as its own custom module whose on-click
  # goes through the Lua dispatcher form Hyprland accepts.
  wsIds = range 1 10;

  wsScript = pkgs.writeShellApplication {
    name = "waybar-hypr-ws";
    runtimeInputs = with pkgs; [
      config.wayland.windowManager.hyprland.package
      jq
      socat
      coreutils
    ];
    text = ''
      id="$1"
      sock="''${XDG_RUNTIME_DIR}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

      emit() {
        active=$(hyprctl activeworkspace -j | jq -r '.id')
        if [ "$active" = "$id" ]; then
          printf '{"text":"%s","class":"focused"}\n' "$id"
        elif hyprctl workspaces -j | jq -e --argjson i "$id" 'any(.[]; .id == $i)' >/dev/null; then
          printf '{"text":"%s","class":"occupied"}\n' "$id"
        else
          printf '{"text":""}\n'
        fi
      }

      # Emit once on start, then re-emit on every relevant Hyprland event.
      emit
      socat -u "UNIX-CONNECT:''${sock}" - 2>/dev/null | while read -r line; do
        case "$line" in
          workspace*|createworkspace*|destroyworkspace*|focusedmon*|moveworkspace*|activespecial*)
            emit
            ;;
        esac
      done
    '';
  };

  wsModules = listToAttrs (map (i:
    nameValuePair "custom/ws${toString i}" {
      format = "{}";
      return-type = "json";
      exec = "${wsScript}/bin/waybar-hypr-ws ${toString i}";
      restart-interval = 2;
      on-click = "hyprctl dispatch 'hl.dsp.focus({ workspace = ${toString i} })'";
      tooltip = false;
    })
  wsIds);

  wsModuleNames = map (i: "custom/ws${toString i}") wsIds;

  wsSelectors = suffix: concatStringsSep ",\n" (map (i: "#custom-ws${toString i}${suffix}") wsIds);

  wsCss = ''
    /* Custom Hyprland workspace buttons (Lua-config compatible) */
    ${wsSelectors ""} {
      padding: 0;
      margin: 0.3em 0.2em;
      box-shadow: 0 -0.2em alpha(@base04, 0.5);
      background: alpha(@base04, 0.25);
    }

    ${wsSelectors ":hover"} {
      box-shadow: 0 -0.2em @base04;
      background: alpha(@base04, 0.5);
    }

    ${wsSelectors ".focused"} {
      box-shadow: 0 -0.2em alpha(@base0F, 0.75);
      background: alpha(@base0F, 0.25);
    }

    ${wsSelectors ".focused:hover"} {
      box-shadow: 0 -0.2em @base0F;
      background: alpha(@base0F, 0.5);
    }
  '';
in {
  config = mkIf config.graphical.enable {
    # A `nixos-rebuild switch` reloads waybar via SIGUSR2 (home-manager's
    # default X-Reload-Triggers + ExecReload for the waybar unit). On a
    # SIGUSR2 reload waybar doesn't respawn the persistent per-workspace
    # `custom/ws*` scripts above, so the workspace section goes blank until a
    # full process restart. Force sd-switch to restart the unit instead.
    systemd.user.services.waybar.Unit."X-SwitchMethod" =
      mkIf config.programs.waybar.systemd.enable "restart";

    programs = {
      # System bar
      waybar = {
        enable = mkDefault isLinux;
        systemd.enable = mkDefault isLinux;

        # https://github.com/Alexays/Waybar/wiki/Configuration
        # Number formatting: https://fmt.dev/latest/syntax.html#format-specification-mini-language
        settings = {
          # TODO: use program paths
          mainBar =
            {
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

              modules-left =
                ["custom/launcher"]
                ++ wsModuleNames
                ++ ["hyprland/submap"];

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
                on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
                scroll-step = 1;
              };

              "hyprland/window" = {
                format = "{}";
                max-length = 120;
              };

              tray = {
                icon-size = 18;
                spacing = 10;
              };
            }
            // wsModules;
        };

        style = ''
          * {
            font-family: ${config.font.family};
            font-size: ${builtins.toString config.font.size}px;

            /* Slanted */
            border-radius: 0.3em 0.9em;

            /* None */
            /*border-radius: 0;*/

            outline: none;
            border-color: transparent;
          }

          ${readFile ./bar.css}

          ${wsCss}
        '';
      };
    };
  };
}
