{
  config,
  pkgs,
  ...
}: {
  system.defaults = {
    # Recommended for stability:
    # https://nikitabobko.github.io/AeroSpace/guide#a-note-on-displays-have-separate-spaces
    spaces.spans-displays = true;

    NSGlobalDomain = {
      # Drag windows more easily
      NSWindowShouldDragOnGesture = true;

      # No opening animations
      NSAutomaticWindowAnimationsEnabled = false;
    };

    # Don't need the dock
    dock = {
      autohide = true;
      tilesize = 16;
      largesize = 128;
      magnification = true;

      # Disable hot corners
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
    };
  };

  # Color border of active window
  services.jankyborders = {
    enable = true;
    active_color = "gradient(top_right=0xee33ccff,bottom_left=0xee00ff99)";
    inactive_color = "0x00000000";
  };

  services.aerospace = {
    enable = true;
    package = pkgs.unstable.aerospace;

    # TODO:
    # Fullscreen
    # Dialogs: https://nikitabobko.github.io/AeroSpace/guide#dialog-heuristics

    settings = {
      automatically-unhide-macos-hidden-apps = true;
      after-startup-command = ["layout tiles"];
      #on-focus-changed = ["move-mouse window-lazy-center"];
      exec-on-workspace-change = [
        "/bin/sh"
        "-c"
        "${config.services.sketchybar.package}/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE PREV_WORKSPACE=$AEROSPACE_PREV_WORKSPACE"
      ];

      workspace-to-monitor-force-assignment = {
        "1" = "built-in";
        "10" = "secondary";
      };

      on-window-detected =
        map (app: {
          "if".app-id = app;
          run = "layout floating";
          check-further-callbacks = true;
        }) [
          "com.apple.systempreferences"
          "com.cisco.anyconnect.gui"
        ];

      gaps = {
        inner.horizontal = 10;
        inner.vertical = 10;
        outer.left = 10;
        outer.right = 10;
        outer.top = [
          # Bar is already accounted for
          {monitor.built-in = 10;}

          # Need to account for the menu bar
          47
        ];
        outer.bottom = 10;
      };

      mode = let
        change-workspace = "${pkgs.writeShellApplication {
          name = "change-workspace";

          runtimeInputs = [
            config.services.aerospace.package
          ];

          text = ''
            workspace=$1
            window_count="$(aerospace list-windows --workspace "$workspace" --count)"

             if [[ "$window_count" -eq 0 ]]; then
               aerospace summon-workspace "$workspace"
             else
               aerospace workspace "$workspace"
             fi
          '';
        }}/bin/change-workspace";
      in {
        # Commands: https://nikitabobko.github.io/AeroSpace/commands
        main.binding = {
          alt-h = "layout tiles horizontal";
          alt-v = "layout tiles vertical";
          alt-r = "mode resize";
          alt-shift-r = ["layout tiles" "flatten-workspace-tree"]; # Reset layout
          alt-space = "layout floating tiling"; # toggle between floating and tiling
          alt-f = "fullscreen";
          alt-tab = "focus-back-and-forth";
          alt-shift-tab = "workspace-back-and-forth";
          alt-shift-q = "close";

          alt-enter = "exec-and-forget ${pkgs.alacritty}/bin/alacritty";

          alt-left = "focus left --ignore-floating --boundaries all-monitors-outer-frame";
          alt-right = "focus right --ignore-floating --boundaries all-monitors-outer-frame";
          alt-up = "focus up --ignore-floating --boundaries all-monitors-outer-frame";
          alt-down = "focus down --ignore-floating --boundaries all-monitors-outer-frame";

          alt-shift-left = "move left";
          alt-shift-right = "move right";
          alt-shift-up = "move up";
          alt-shift-down = "move down";

          alt-ctrl-left = "move-node-to-monitor left";
          alt-ctrl-right = "move-node-to-monitor right";
          alt-ctrl-up = "move-node-to-monitor up";
          alt-ctrl-down = "move-node-to-monitor down";

          # alt-1 = "workspace 1";
          # alt-2 = "workspace 2";
          # alt-3 = "workspace 3";
          # alt-4 = "workspace 4";
          # alt-5 = "workspace 5";
          # alt-6 = "workspace 6";
          # alt-7 = "workspace 7";
          # alt-8 = "workspace 8";
          # alt-9 = "workspace 9";
          # alt-0 = "workspace 10";

          alt-1 = "exec-and-forget ${change-workspace} 1";
          alt-2 = "exec-and-forget ${change-workspace} 2";
          alt-3 = "exec-and-forget ${change-workspace} 3";
          alt-4 = "exec-and-forget ${change-workspace} 4";
          alt-5 = "exec-and-forget ${change-workspace} 5";
          alt-6 = "exec-and-forget ${change-workspace} 6";
          alt-7 = "exec-and-forget ${change-workspace} 7";
          alt-8 = "exec-and-forget ${change-workspace} 8";
          alt-9 = "exec-and-forget ${change-workspace} 9";
          alt-0 = "exec-and-forget ${change-workspace} 10";

          alt-shift-1 = "move-node-to-workspace 1";
          alt-shift-2 = "move-node-to-workspace 2";
          alt-shift-3 = "move-node-to-workspace 3";
          alt-shift-4 = "move-node-to-workspace 4";
          alt-shift-5 = "move-node-to-workspace 5";
          alt-shift-6 = "move-node-to-workspace 6";
          alt-shift-7 = "move-node-to-workspace 7";
          alt-shift-8 = "move-node-to-workspace 8";
          alt-shift-9 = "move-node-to-workspace 9";
          alt-shift-0 = "move-node-to-workspace 10";
        };

        resize.binding = {
          esc = "mode main";

          alt-left = "resize width -50";
          alt-right = "resize width +50";
          alt-up = "resize height -50";
          alt-down = "resize height +50";

          alt-minus = "resize smart -50";
          alt-equal = "resize smart +50";
        };
      };
    };
  };

  services.yabai = {
    enable = false;

    package = pkgs.unstable.yabai;

    # https://github.com/koekeishiya/yabai/wiki/Configuration#configuration-file
    config = {
      # bsp or float (default: bsp)
      layout = "bsp";

      # Set all padding and gaps to 20pt (default: 0)
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      window_gap = 10;

      focus_follows_mouse = "autoraise";
      mouse_follows_focus = "on";

      # Mouse actions
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";

      # Window borders
      window_border = "on";
      window_border_width = 1;
      window_border_radius = 13;
      window_border_blur = "off";
      active_window_border_color = "0xFFB928B9";
      normal_window_border_color = "0x00B9B9B9";

      # Window creation
      window_origin_display = "focused";

      # Spacebar integration
      external_bar = "all:${config.services.spacebar.config.height}:0";

      # Split
      # split_ratio = 0.5;
      auto_balance = "on";

      # mouse_drop_action = "stack";
    };

    extraConfig = ''
      # Window rules
      # Show running windows with: yabai -m query --windows
      yabai -m rule --add app="System Settings" manage=off
      yabai -m rule --add app="Cisco Secure Client" manage=off layer=above
      yabai -m rule --add app="Cisco AnyConnect Secure Mobility Client" manage=off layer=above
      yabai -m rule --add label=FloatTreeTabConfirmation app="Firefox" title="Close.*tabs?" manage=off
      yabai -m rule --add label=FloatIntelliJIntro app="IntelliJ IDEA" title="Welcome to IntelliJ IDEA" manage=off

      # Steam popups are especially annoying, and mouse focus doesn't seem to know the window name before acting.
      # To work around this, mouse foxus is disabled by default until the window is known to not be Steam-related
      yabai -m rule --add label=FloatSteam app="Steam" manage=off
      yabai -m rule --add label=FocusAll app!="Steam" mouse_follows_focus=on

      # Kill iTunes when I press `play` and forget that my headphones are still connected
      yabai -m signal --add event=window_created app=iTunes title=iTunes action="killall iTunes"
    '';
  };
}
