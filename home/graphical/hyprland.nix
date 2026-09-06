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
    # Monitor layout editor. DMS's own display config writes classic `monitor=`
    # syntax the Lua config parser can't consume; nwg-displays writes the
    # monitors.lua `require`d below.
    home.packages = [pkgs.nwg-displays];

    # Tie Wayland-targeted user services to Hyprland's session target so they
    # only start once Hyprland's env (HYPRLAND_INSTANCE_SIGNATURE,
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

    # start-hyprland is a supervisor: it runs Hyprland, and on an unclean exit
    # restarts it in safe mode rather than letting the login session end. Its own
    # log says which path was taken ("Hyprland exit cleanly." vs "Hyprland exit
    # not-cleanly, restarting"), and that is the only record of why a session
    # died -- Hyprland's own log just stops. Left on the tty it scrolls away with
    # the session, so route it to the journal, where it survives the teardown and
    # lines up with the logind/kernel messages for the same instant:
    #   journalctl -t hyprland-session
    # Skipped under the DMS greeter: greetd owns tty1 and launches
    # start-hyprland itself, so this would be a second, competing launch.
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
    };

    # View logs with: `tail -f /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log`
    wayland.windowManager.hyprland = let
      mod = "ALT";
      inherit (lib.generators) mkLuaInline;

      # The DMS CLI ships inside dms-shell; pkgs.dms is an unrelated DLNA server.
      dms = "${osConfig.programs.dms-shell.package}/bin/dms";

      # Volume, brightness and media all go through the shell rather than the
      # underlying tool -- that's what makes its OSDs appear. `dms ipc call
      # <target>` with no function lists what a target accepts while it runs.
      ipc = target: fn: "${dms} ipc call ${target} ${fn}";

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
        # The bar, notifications, clipboard history and wallpaper are all DMS,
        # started as a systemd unit tied to hyprland-session.target.
        on = {
          _args = [
            "hyprland.start"
            (mkLuaInline ''
              function()
                hl.exec_cmd("polkit-agent") -- Authentication agent
                hl.exec_cmd(${builtins.toJSON "${pkgs.dex}/bin/dex -a -s /etc/xdg/autostart/:~/.config/autostart/"}) -- Desktop entries
              end'')
          ];
        };

        # Keybindings. See https://wiki.hypr.land/Configuring/Basics/Binds/
        bind =
          [
            # Open terminal
            (mkExec "${mod} + RETURN" "alacritty")

            # Open the power menu
            (mkExec "${mod} + SHIFT + E" (ipc "powermenu" "toggle"))

            # Close the focused window
            (mkBind "${mod} + SHIFT + Q" "hl.dsp.window.close()")

            # Start the application launcher
            (mkExec "${mod} + D" (ipc "spotlight" "toggle"))

            # Reload the renderer. exec_raw bridges to the classic dispatcher;
            # under the Lua config Hyprland rejects plain string IPC dispatch.
            (mkBind "${mod} + SHIFT + R" ''hl.dsp.exec_raw("forcerendererreload")'')

            # Lock
            (mkExec "${mod} + SHIFT + L" (ipc "lock" "lock"))
            (mkExec "SUPER + CTRL + Q" (ipc "lock" "lock"))

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
            (mkExecFlags "XF86AudioRaiseVolume" (ipc "audio" "increment 5") {
              repeating = true;
              locked = true;
            })
            (mkExecFlags "XF86AudioLowerVolume" (ipc "audio" "decrement 5") {
              repeating = true;
              locked = true;
            })

            # Brightness: repeating, work on lock screen. DMS's second argument
            # is the device; "" means its default backlight.
            (mkExecFlags "XF86MonBrightnessUp" (ipc "brightness" ''increment 5 ""'') {
              repeating = true;
              locked = true;
            })
            (mkExecFlags "XF86MonBrightnessDown" (ipc "brightness" ''decrement 5 ""'') {
              repeating = true;
              locked = true;
            })

            # Mute / mic mute / media transport, work on lock screen
            (mkExecFlags "XF86AudioMute" (ipc "audio" "mute") {locked = true;})
            (mkExecFlags "XF86AudioMicMute" (ipc "audio" "micmute") {locked = true;})
            (mkExecFlags "XF86AudioPlay" (ipc "mpris" "playPause") {locked = true;})
            (mkExecFlags "XF86AudioPause" (ipc "mpris" "playPause") {locked = true;})
            (mkExecFlags "XF86AudioNext" (ipc "mpris" "next") {locked = true;})
            (mkExecFlags "XF86AudioPrev" (ipc "mpris" "previous") {locked = true;})

            # Lock on lid close. Find switch names with: `hyprctl devices -j`
            (mkExecFlags "switch:Lid Switch" (ipc "lock" "lock") {locked = true;})

            # Clipboard history
            (mkExec "${mod} + V" (ipc "clipboard" "toggle"))

            # Notification center
            (mkExec "${mod} + N" (ipc "notifications" "toggle"))

            # Scratchpad notes
            (mkExec "${mod} + SHIFT + N" (ipc "notepad" "toggle"))

            # Control center: network, bluetooth, audio, night mode, inhibit
            (mkExec "${mod} + C" (ipc "control-center" "toggle"))

            # Window overview
            (mkExec "${mod} + TAB" (ipc "hypr" "toggleOverview"))

            # Process list
            (mkExec "${mod} + M" (ipc "processlist" "focusOrToggle"))

            # Shell settings
            (mkExec "${mod} + comma" (ipc "settings" "focusOrToggle"))

            # Keybind cheatsheet, read out of the running Hyprland config
            (mkExec "${mod} + SHIFT + slash" (ipc "keybinds" "toggle hyprland"))

            # Colour picker
            (mkExec "${mod} + SHIFT + P" (ipc "color-picker" "toggle"))

            # TODO:
            # Splitting
            # Parent container selection
            # Title-based floating rules
            # Picture-in-Picture rules
            # Monitor directions & sizes
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
  };
}
