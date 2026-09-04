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
    home.packages = with pkgs;
      [
        # Monitor layout editor. Kept under DMS: its display config writes
        # classic `monitor=` syntax to ~/.config/hypr/dms/outputs.conf and
        # appends a `source =` line to hyprland.conf, neither of which the Lua
        # config parser can consume. nwg-displays writes monitors.lua, which
        # the `pcall(require, "monitors")` below already picks up.
        nwg-displays
      ]
      # Colour picker: DMS has one on `dms ipc call color-picker toggle`.
      ++ optional (!config.dms.enable) hyprpicker;

    # Tie Wayland-targeted user services (waybar, etc.) to Hyprland's session
    # target so they only start once Hyprland's env (HYPRLAND_INSTANCE_SIGNATURE,
    # WAYLAND_DISPLAY, ...) has been imported into the systemd user environment.
    wayland.systemd.target = "hyprland-session.target";

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

    # Launcher. Replaced by DMS's spotlight.
    programs.wofi.enable = !config.dms.enable;

    # Lock screen. Replaced by DMS's (Modules/Lock), which authenticates
    # through /etc/pam.d/dankshell. Settings are left defined either way so
    # flipping `dms.enable` off restores a working hyprlock.
    programs.hyprlock = {
      enable = !config.dms.enable;
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

    # start-hyprland is a supervisor: it runs Hyprland, and on an unclean exit
    # restarts it in safe mode rather than letting the login session end. Its own
    # log says which path was taken ("Hyprland exit cleanly." vs "Hyprland exit
    # not-cleanly, restarting"), and that is the only record of why a session
    # died -- Hyprland's own log just stops. Left on the tty it scrolls away with
    # the session, so route it to the journal, where it survives the teardown and
    # lines up with the logind/kernel messages for the same instant:
    #   journalctl -t hyprland-session
    # Skipped under the DMS greeter: greetd owns tty1 and launches the session
    # itself (via start-hyprland, the same supervisor), so this would be a
    # second, competing launch.
    programs.fish.loginShellInit = optionalString (config.wayland.windowManager.hyprland.enable && !osConfig.dms.greeter.enable) ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]
        exec systemd-cat --identifier=hyprland-session --stderr-priority=warning start-hyprland
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

      configFile = mkIf (!config.dms.enable) {
        # Set wallpaper. DMS draws the wallpaper itself
        # (Modules/WallpaperBackground.qml) and derives the Material palette
        # from it via matugen, so hyprpaper is redundant under it.
        "hypr/hyprpaper.conf".text = ''
          ipc = off
          splash = false

          wallpaper {
            monitor =
            path = ${config.wallpapers.default}
            fit_mode = cover
          }
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
      inherit (lib.generators) mkLuaInline;

      wpctl = "${pkgs.wireplumber}/bin/wpctl";
      playerctl = "${pkgs.playerctl}/bin/playerctl";
      brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
      hyprlock = "${config.programs.hyprlock.package}/bin/hyprlock";

      # The DMS CLI ships inside dms-shell (pkgs.dms is an unrelated DLNA
      # server). Installed system-wide by programs.dms-shell, but referenced by
      # store path here to match how every other bind resolves its binary.
      dms = "${osConfig.programs.dms-shell.package}/bin/dms";

      # Prefer DMS's IPC for anything the shell owns -- routing volume,
      # brightness and media through it is what makes its OSD appear -- and
      # fall back to driving the underlying tool directly when it's disabled.
      # Targets and function names are those in DMSShellIPC.qml and the
      # per-service IpcHandlers.
      dmsOr = target: fn: fallback:
        if config.dms.enable
        then "${dms} ipc call ${target} ${fn}"
        else fallback;

      toggle-setting = "${pkgs.writeShellApplication {
        name = "toggle-setting";

        text = ''
          #!/bin/sh
          set -e

          if [[ $# -ne 1 ]]; then
            echo "Usage: toggle-setting <section>:<option>"
            exit 1
          fi

          section="''${1%%:*}"
          key="''${1#*:}"

          # `hyprctl getoption` prints the value on the first line. Newer
          # Hyprland reports bools as `bool: true`/`bool: false` (older builds
          # used `int: 1`), so accept both and flip to the opposite.
          cur="$(hyprctl getoption "$1" | awk 'NR==1 {print $2}')"
          if [[ "$cur" == "true" || "$cur" == "1" ]]; then
            new=false
          else
            new=true
          fi

          # Under the Lua config parser `hyprctl keyword` is rejected
          # ("keyword can't work with non-legacy parsers"), so apply the change
          # through `hyprctl eval` against the `hl.config` API instead.
          hyprctl eval "hl.config({ $section = { $key = $new } })"
        '';
      }}/bin/toggle-setting";

      # Helpers that build hl.bind(...) arg lists. `dispatch` is a raw Lua
      # expression (e.g. `hl.dsp.exec_cmd("foo")`).
      mkBind = key: dispatch: {_args = [key (mkLuaInline dispatch)];};
      mkBindFlags = key: dispatch: flags: {_args = [key (mkLuaInline dispatch) flags];};
      mkExec = key: cmd: mkBind key ''hl.dsp.exec_cmd(${builtins.toJSON cmd})'';
      mkExecFlags = key: cmd: flags: mkBindFlags key ''hl.dsp.exec_cmd(${builtins.toJSON cmd})'' flags;

      directionMap = {
        left = "l";
        right = "r";
        up = "u";
        down = "d";
      };
      directionBinds = concatMap (dir: let
        d = directionMap.${dir};
      in [
        (mkBind "${mod} + ${dir}" ''hl.dsp.focus({ direction = "${d}" })'')
        (mkBind "${mod} + SHIFT + ${dir}" ''hl.dsp.window.move({ direction = "${d}" })'')
        (mkBind "${mod} + CTRL + ${dir}" ''hl.dsp.window.swap({ direction = "${d}" })'')
      ]) ["left" "right" "up" "down"];

      workspaceBinds = concatMap (i: let
        ws = toString (
          if i == 0
          then 10
          else i
        );
        n = toString i;
      in [
        (mkBind "${mod} + ${n}" "hl.dsp.focus({ workspace = ${ws} })")
        (mkBind "${mod} + SHIFT + ${n}" "hl.dsp.window.move({ workspace = ${ws} })")
      ]) (lib.range 0 9);
    in {
      enable = mkDefault (!osConfig.services.desktopManager.plasma6.enable);
      configType = "lua";

      # nwg-displays writes ~/.config/hypr/{monitors,workspaces}.lua on Apply.
      # extraConfig renders at the end of hyprland.lua, after the static
      # `monitor` rules below — Hyprland resolves monitor rules last-match-wins,
      # so the nwg-displays layout overrides them once it exists. pcall keeps a
      # missing file from erroring the config before the first Apply.
      extraConfig = ''
        pcall(require, "monitors")
        pcall(require, "workspaces")
      '';

      # https://wiki.hypr.land/Configuring/Basics/Variables/
      settings = {
        # Local Lua variable: `local mod = "ALT"`.
        mod = {_var = mod;};

        # Global options. See https://wiki.hypr.land/Configuring/Basics/Variables/
        config = {
          general = {
            "col.active_border" = {
              colors = ["rgba(33ccffee)" "rgba(00ff99ee)"];
              angle = 45;
            };
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
            dim_strength = 0.2;

            blur = {
              noise = 0.1;
            };
          };
        };

        # Monitors. See https://wiki.hypr.land/Configuring/Basics/Monitors/
        monitor = [
          # PiKVM
          {
            output = "desc:The Linux Foundation PiKVM CAFEBABE";
            mode = "1920x1080@24";
            position = "auto";
            scale = 1;
          }
          # Display Stub Adapter
          {
            output = "desc:AOC 28E850";
            mode = "2560x1440@24Hz";
            position = "auto";
            scale = 1;
          }
          # Top Left (Anker display adapter)
          {
            output = "desc:Digital Projection Limited";
            mode = "preferred";
            position = "0x0";
            scale = 1;
          }
          # Top Right
          {
            output = "desc:HYC CO. LTD. HDMI";
            mode = "preferred";
            position = "2560x0";
            scale = 1;
          }
          # Laptop
          {
            output = "desc:LG Display 0x062F";
            mode = "preferred";
            position = "1600x1440";
            scale = 1;
          }
          # Default fallback
          {
            output = "";
            mode = "preferred";
            position = "auto";
            scale = 1;
          }
        ];

        # Faster animations. See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
        animation = [
          {
            leaf = "global";
            enabled = true;
            speed = 5;
            bezier = "default";
          }
        ];

        # Touchpad gestures. See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
        gesture = [
          # 3-finger swipe to change workspaces
          {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          }
          # 3-finger vertical to maximize
          {
            fingers = 3;
            direction = "vertical";
            action = "fullscreen";
            mode = "maximize";
          }
        ];

        # Window rules. See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
        window_rule = [
          {
            match = {title = "Tree Style Tab";};
            border_color = "rgb(ff0000)";
          }
          {
            match = {class = "Alacritty";};
            opacity = "0.8 override";
          }
          # Tooltip for SweetHome3D
          {
            match = {title = "win1";};
            no_focus = true;
          }
        ];

        # Autostart on session start. See https://wiki.hypr.land/Configuring/Basics/Autostart/
        #
        # The status bar is managed via systemd, tied to
        # hyprland-session.target -- programs.waybar.systemd normally, or
        # programs.dms-shell.systemd on the system side under DMS. DMS also
        # subsumes the notification daemon, clipboard manager and wallpaper,
        # so those only autostart without it.
        on = let
          autostart =
            [
              {
                cmd = "polkit-agent";
                note = "Authentication agent";
              }
              {
                cmd = "${pkgs.dex}/bin/dex -a -s /etc/xdg/autostart/:~/.config/autostart/";
                note = "Desktop entries";
              }
            ]
            ++ optionals (!config.dms.enable) [
              {
                cmd = "${config.services.mako.package}/bin/mako";
                note = "Notifications";
              }
              {
                cmd = "${pkgs.copyq}/bin/copyq";
                note = "Clipboard manager";
              }
              {
                cmd = "${pkgs.hyprpaper}/bin/hyprpaper";
                note = "Wallpaper";
              }
            ];
        in {
          _args = [
            "hyprland.start"
            (mkLuaInline ''
              function()
              ${concatMapStringsSep "\n" ({
                cmd,
                note,
              }: "  hl.exec_cmd(${builtins.toJSON cmd}) -- ${note}")
              autostart}
              end'')
          ];
        };

        # Keybindings. See https://wiki.hypr.land/Configuring/Basics/Binds/
        bind =
          [
            # Open terminal
            (mkExec "${mod} + RETURN" "alacritty")

            # Open the power menu
            (mkExec "${mod} + SHIFT + E" (dmsOr "powermenu" "toggle" "${pkgs.callPackage ./waybar/power.nix {}}/bin/power.sh"))

            # Close the focused window
            (mkBind "${mod} + SHIFT + Q" "hl.dsp.window.close()")

            # Start the application launcher
            (mkExec "${mod} + D" (dmsOr "spotlight" "toggle" "${pkgs.wofi}/bin/wofi -c ~/.config/wofi/config -I"))

            # Reload the renderer. exec_raw bridges to the classic dispatcher;
            # under the Lua config Hyprland rejects plain string IPC dispatch.
            (mkBind "${mod} + SHIFT + R" ''hl.dsp.exec_raw("forcerendererreload")'')

            # Lock
            (mkExec "${mod} + SHIFT + L" (dmsOr "lock" "lock" hyprlock))

            # Toggle dimming
            (mkExec "${mod} + SHIFT + D" "${toggle-setting} decoration:dim_inactive")

            # Fullscreen (maximize style: keeps margins)
            (mkBind "${mod} + F" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')

            # Toggle floating
            (mkBind "${mod} + space" "hl.dsp.window.float()")

            # Enter the resize submap
            (mkBind "${mod} + R" ''hl.dsp.submap("resize")'')

            # Enter the passthrough submap
            (mkBind "${mod} + P" ''hl.dsp.submap("passthrough")'')

            # Media keys: repeating, work on lock screen
            (mkExecFlags "XF86AudioRaiseVolume" (dmsOr "audio" "increment 5" "${wpctl} set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+") {
              repeating = true;
              locked = true;
            })
            (mkExecFlags "XF86AudioLowerVolume" (dmsOr "audio" "decrement 5" "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-") {
              repeating = true;
              locked = true;
            })

            # Brightness: repeating, work on lock screen. DMS's brightness
            # target takes a device as its second argument; "" means whichever
            # backlight it considers default.
            (mkExecFlags "XF86MonBrightnessUp" (dmsOr "brightness" ''increment 5 ""'' "${brightnessctl} -c backlight set +5%") {
              repeating = true;
              locked = true;
            })
            (mkExecFlags "XF86MonBrightnessDown" (dmsOr "brightness" ''decrement 5 ""'' "${brightnessctl} -c backlight set 5%-") {
              repeating = true;
              locked = true;
            })

            # Mute / mic mute / media transport, work on lock screen
            (mkExecFlags "XF86AudioMute" (dmsOr "audio" "mute" "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle") {locked = true;})
            (mkExecFlags "XF86AudioMicMute" (dmsOr "audio" "micmute" "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle") {locked = true;})
            (mkExecFlags "XF86AudioPlay" (dmsOr "mpris" "playPause" "${playerctl} play") {locked = true;})
            (mkExecFlags "XF86AudioPause" (dmsOr "mpris" "playPause" "${playerctl} pause") {locked = true;})
            (mkExecFlags "XF86AudioNext" (dmsOr "mpris" "next" "${playerctl} next") {locked = true;})
            (mkExecFlags "XF86AudioPrev" (dmsOr "mpris" "previous" "${playerctl} previous") {locked = true;})

            # Lock on lid close. Find switch names with: `hyprctl devices -j`
            (mkExecFlags "switch:Lid Switch" (dmsOr "lock" "lock" hyprlock) {locked = true;})

            # TODO:
            # Splitting
            # Parent container selection
            # Title-based floating rules
            # Picture-in-Picture rules
            # Idle inhibit
            # Monitor directions & sizes
            # Theme
          ]
          # Surfaces that only exist under DMS. Targets and functions verified
          # against DMSShellIPC.qml; `dms ipc call <target>` with no function
          # lists what a target accepts while the shell is running.
          ++ optionals config.dms.enable [
            # Clipboard history (replaces copyq)
            (mkExec "${mod} + V" (dmsOr "clipboard" "toggle" null))

            # Notification center
            (mkExec "${mod} + N" (dmsOr "notifications" "toggle" null))

            # Scratchpad notes
            (mkExec "${mod} + SHIFT + N" (dmsOr "notepad" "toggle" null))

            # Control center: network, bluetooth, audio, night mode, inhibit
            (mkExec "${mod} + C" (dmsOr "control-center" "toggle" null))

            # Window overview
            (mkExec "${mod} + TAB" (dmsOr "hypr" "toggleOverview" null))

            # Process list (replaces the waybar cpu/memory click-throughs)
            (mkExec "${mod} + M" (dmsOr "processlist" "focusOrToggle" null))

            # Shell settings
            (mkExec "${mod} + comma" (dmsOr "settings" "focusOrToggle" null))

            # Keybind cheatsheet, read out of the running Hyprland config
            (mkExec "${mod} + SHIFT + slash" (dmsOr "keybinds" "toggle hyprland" null))

            # Colour picker (replaces hyprpicker)
            (mkExec "${mod} + SHIFT + P" (dmsOr "color-picker" "toggle" null))
          ]
          ++ directionBinds
          ++ workspaceBinds;
      };

      # Submaps. See https://wiki.hypr.land/Configuring/Basics/Binds/#submaps
      submaps = {
        resize.settings.bind = [
          # Repeatable resize binds
          {_args = ["right" (mkLuaInline "hl.dsp.window.resize({ x = 10, y = 0, relative = true })") {repeating = true;}];}
          {_args = ["left" (mkLuaInline "hl.dsp.window.resize({ x = -10, y = 0, relative = true })") {repeating = true;}];}
          {_args = ["up" (mkLuaInline "hl.dsp.window.resize({ x = 0, y = -10, relative = true })") {repeating = true;}];}
          {_args = ["down" (mkLuaInline "hl.dsp.window.resize({ x = 0, y = 10, relative = true })") {repeating = true;}];}

          # Exit resize mode
          {_args = ["escape" (mkLuaInline ''hl.dsp.submap("reset")'')];}
          {_args = ["${mod} + R" (mkLuaInline ''hl.dsp.submap("reset")'')];}
        ];

        passthrough.settings.bind = [
          # Exit passthrough mode
          {_args = ["${mod} + escape" (mkLuaInline ''hl.dsp.submap("reset")'')];}
          {_args = ["${mod} + P" (mkLuaInline ''hl.dsp.submap("reset")'')];}
        ];
      };
    };

    services = {
      # Notifications. DMS runs its own notification server
      # (Services/NotificationService.qml) plus a notification center, and the
      # two would fight over the org.freedesktop.Notifications name.
      mako.enable = mkDefault (isLinux && !config.dms.enable);

      # Idle management. DMS's IdleService covers the same ground -- monitor
      # off, lock and suspend timeouts, with separate AC and battery values and
      # idle-inhibitor support -- driven from its own settings rather than
      # here. See `dms.settings` in ./dms.nix to pin those declaratively.
      hypridle = {
        enable = !config.dms.enable;

        settings = {
          general = {
            lock_cmd = "${config.programs.hyprlock.package}/bin/hyprlock";
            before_sleep_cmd = "${config.programs.hyprlock.package}/bin/hyprlock";
            after_sleep_cmd = "hyprctl dispatch 'hl.dsp.exec_raw(\"dpms on\")'";
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
              on-timeout = "hyprctl dispatch 'hl.dsp.exec_raw(\"dpms off\")'";
              on-resume = "hyprctl dispatch 'hl.dsp.exec_raw(\"dpms on\")' && brightnessctl -r ";
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
