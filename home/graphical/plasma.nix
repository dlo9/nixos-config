{
  config,
  pkgs,
  lib,
  isLinux,
  osConfig,
  ...
}:
with lib; let
  plasmaEnabled = osConfig.services.desktopManager.plasma6.enable;
in {
  config = mkIf (plasmaEnabled && config.graphical.enable && isLinux) {
    home.packages = [
      pkgs.dlo9.fluid-tile
      pkgs.kdePackages.dolphin
    ];

    programs.plasma = {
      enable = true;

      workspace = {
        wallpaper = "${config.wallpapers.default}";
      };

      kwin = {
        virtualDesktops = {
          rows = 1;
          number = 10;
          names = ["Desktop 1" "Desktop 2" "Desktop 3" "Desktop 4" "Desktop 5" "Desktop 6" "Desktop 7" "Desktop 8" "Desktop 9" "Desktop 10"];
        };
      };

      configFile = {
        # Enable fluid-tile tiling plugin
        kwinrc.Plugins."fluid-tileEnabled" = true;

        # fluid-tile settings
        "kwinrc"."Script-fluid-tile" = {
          MaximizeExtend = true;
          ModalsIgnore = true;
          LayoutDefault = 2;
        };

        # Lock screen settings
        kscreenlockerrc = {
          Daemon = {
            Autolock = true;
            LockGrace = 0;
            Timeout = 5; # Lock after 5 minutes
          };
        };

        # Power management: screen off after 10 min, suspend after 15 min
        powermanagementprofilesrc = {
          "AC/DPMSControl" = {
            idleTime = 600; # 10 minutes in seconds
            lockBeforeTurnOff = 0;
          };
          "AC/SuspendSession" = {
            idleTime = 900000; # 15 minutes in milliseconds
            suspendType = 1; # Suspend to RAM
          };
          "Battery/DPMSControl" = {
            idleTime = 600;
            lockBeforeTurnOff = 0;
          };
          "Battery/SuspendSession" = {
            idleTime = 900000;
            suspendType = 1;
          };
        };
      };

      shortcuts = {
        # Launch Alacritty
        "services/Alacritty.desktop"._launch = "Alt+Return";

        kwin = {
          # Close window (clear default Alt+F4)
          "Window Close" = "Alt+Shift+Q";

          # KRunner (app launcher)
          # Note: KRunner default is Alt+Space or Alt+F2; we remap to Alt+D
          # The actual KRunner shortcut is set below

          # Reconfigure KWin
          "Recomposite" = "Alt+Shift+R";

          # Window focus (directional, native KWin)
          "Switch Window Down" = "Alt+Down";
          "Switch Window Left" = "Alt+Left";
          "Switch Window Right" = "Alt+Right";
          "Switch Window Up" = "Alt+Up";

          # Move window to tile (native KWin quick tiling)
          "Custom Quick Tile Window to the Bottom" = "Alt+Shift+Down";
          "Custom Quick Tile Window to the Top" = "Alt+Shift+Up";
          "Custom Quick Tile Window to the Left" = "Alt+Shift+Left";
          "Custom Quick Tile Window to the Right" = "Alt+Shift+Right";

          # fluid-tile shortcuts
          "FluidtileToggleWindowBlocklist" = "Alt+Ctrl+F";
          "FluidtileChangeTileLayout" = "Alt+Ctrl+Shift+F";

          # Switch desktops
          "Switch to Desktop 1" = "Alt+1";
          "Switch to Desktop 2" = "Alt+2";
          "Switch to Desktop 3" = "Alt+3";
          "Switch to Desktop 4" = "Alt+4";
          "Switch to Desktop 5" = "Alt+5";
          "Switch to Desktop 6" = "Alt+6";
          "Switch to Desktop 7" = "Alt+7";
          "Switch to Desktop 8" = "Alt+8";
          "Switch to Desktop 9" = "Alt+9";
          "Switch to Desktop 10" = "Alt+0";

          # Move window to desktop
          "Window to Desktop 1" = "Alt+Shift+1";
          "Window to Desktop 2" = "Alt+Shift+2";
          "Window to Desktop 3" = "Alt+Shift+3";
          "Window to Desktop 4" = "Alt+Shift+4";
          "Window to Desktop 5" = "Alt+Shift+5";
          "Window to Desktop 6" = "Alt+Shift+6";
          "Window to Desktop 7" = "Alt+Shift+7";
          "Window to Desktop 8" = "Alt+Shift+8";
          "Window to Desktop 9" = "Alt+Shift+9";
          "Window to Desktop 10" = "Alt+Shift+0";

          # Maximize window
          "Window Maximize" = "Alt+F";

          # Toggle floating
          "Window Quick Tile Toggle" = "Alt+Space";
        };

        # Lock session
        ksmserver = {
          "Lock Session" = "Alt+Shift+L";
        };

        # Log out dialog
        "org.kde.ksmserver" = {
          "Log Out" = "Alt+Shift+E";
        };

        # KRunner
        "org.kde.krunner.desktop" = {
          _launch = "Alt+D";
        };
      };
    };
  };
}
