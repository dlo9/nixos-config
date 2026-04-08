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
      pkgs.polonium
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
        # Enable Polonium tiling plugin
        kwinrc.Plugins.poloniumEnabled = true;

        # Polonium settings
        kwinrc.Polonium = {
          BorderVisibility = 1; # Show borders
          Engines = "BTree";
        };

        # Window decoration: ensure borders are visible
        kwinrc."org.kde.kdecoration2" = {
          BorderSize = 2; # Normal borders
          BorderSizeAuto = false;
        };

        # Active/inactive window border colors
        kdeglobals.WM = {
          activeBackground = "61,174,233";
          activeForeground = "255,255,255";
          inactiveBackground = "49,54,59";
          inactiveForeground = "161,169,177";
          activeBlend = "61,174,233";
          inactiveBlend = "49,54,59";
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
          # Close window
          "Window Close" = "Alt+Shift+Q";

          # Reconfigure KWin
          "Recomposite" = "Alt+Shift+R";

          # Clear stale Krohnkite shortcuts that conflict
          "KrohnkiteFocusDown" = "none";
          "KrohnkiteFocusLeft" = "none";
          "KrohnkiteFocusRight" = "none";
          "KrohnkiteFocusUp" = "none";
          "KrohnkiteFocusNext" = "none";
          "KrohnkiteFocusPrev" = "none";
          "KrohnkiteRotate" = "none";
          "KrohnkiteFloatAll" = "none";
          "KrohnkiteBTreeLayout" = "none";
          "KrohnkiteMonocleLayout" = "none";
          "KrohnkiteSetMaster" = "none";
          "KrohnkiteIncrease" = "none";
          "KrohnkiteGrowHeight" = "none";
          "KrohnkiteShrinkHeight" = "none";
          "KrohnkiteShrinkWidth" = "none";
          "KrohnkitegrowWidth" = "none";
          "KrohnkiteToggleFloat" = "none";

          # Clear stale Quick Tile shortcuts that conflict
          "Custom Quick Tile Window to the Bottom" = "none";
          "Custom Quick Tile Window to the Left" = "none";
          "Custom Quick Tile Window to the Right" = "none";
          "Custom Quick Tile Window to the Top" = "none";

          # Clear stale Fluid Tile shortcuts
          "FluidtileChangeTileLayout" = "none";
          "FluidtileToggleWindowBlocklist" = "none";

          # Polonium: Focus window (directional)
          "PoloniumFocusAbove" = "Alt+Up";
          "PoloniumFocusBelow" = "Alt+Down";
          "PoloniumFocusLeft" = "Alt+Left";
          "PoloniumFocusRight" = "Alt+Right";

          # Polonium: Move/Insert window
          "PoloniumInsertAbove" = "Alt+Shift+Up";
          "PoloniumInsertBelow" = "Alt+Shift+Down";
          "PoloniumInsertLeft" = "Alt+Shift+Left";
          "PoloniumInsertRight" = "Alt+Shift+Right";

          # Clear KWin Switch Window (using Polonium focus instead)
          "Switch Window Down" = "none";
          "Switch Window Left" = "none";
          "Switch Window Right" = "none";
          "Switch Window Up" = "none";

          # Clear Pack Window (using Polonium insert instead)
          "Pack Window Down" = "none";
          "Pack Window Left" = "none";
          "Pack Window Right" = "none";
          "Pack Window Up" = "none";

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

          # Toggle floating (Polonium)
          "PoloniumFloatingToggle" = "Alt+Space";

          # Polonium resize cycle
          "PoloniumResizeActiveWindow" = "Alt+R";
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
