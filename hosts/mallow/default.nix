{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  barHeight = "26";
in {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix = {
    package = pkgs.nix;

    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';

    gc = {
      automatic = true;

      interval = {
        Hour = 12;
        Minute = 15;
      };

      options = "--delete-older-than 14d";
      user = "dorchard";
    };
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  security.pki.certificateFiles = [
    ./ca-certificates.crt
  ];

  homebrew = {
    enable = true;

    # Workaround for EULA
    # https://github.com/microsoft/homebrew-mssql-release/issues/86
    extraConfig = ''
      module Utils
        ENV['HOMEBREW_ACCEPT_EULA']='y'
      end

      brew "mssql-tools18"
    '';

    taps = [
      {
        name = "microsoft/mssql-release";
        clone_target = "https://github.com/Microsoft/homebrew-mssql-release";
        force_auto_update = true;
      }
    ];

    brews = [
      "kafka"
      "pyenv"
      "jenv"

      "unixodbc"
      "msodbcsql18"
    ];

    casks = [
      "docker"
      "firefox"
      "google-drive"
      "jdk-mission-control"
      "nosqlbooster-for-mongodb"
      "sensiblesidebuttons"
    ];
  };

  services.yabai = {
    enable = true;

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
      external_bar = "all:${barHeight}:0";
    };

    extraConfig = ''
      # Window rules
      yabai -m rule --add label=FloatSystemPreferences app="System Preferences" manage=off
      yabai -m rule --add label=FloatVPN app="Cisco AnyConnect Secure Mobility Client" manage=off
      yabai -m rule --add label=FloatJAMF app="Jamf Connect Sync" title="Sign In" manage=off
      yabai -m rule --add label=FloatTreeTabConfirmation app="Firefox" title="Close.*tabs?" manage=off
      yabai -m rule --add label=FloatIntelliJIntro app="IntelliJ IDEA" title="Welcome to IntelliJ IDEA" manage=off
      yabai -m rule --add label=FloatColorMeter app="Digital Color Meter" manage=off

      # Steam popups are especially annoying, and mouse focus doesn't seem to know the window name before acting.
      # To work around this, mouse foxus is disabled by default until the window is known to not be Steam-related
      yabai -m rule --add label=FloatSteam app="Steam" manage=off
      yabai -m rule --add label=FocusAll app!="Steam" mouse_follows_focus=on

      # Kill iTunes when I press `play` and forget that my headphones are still connected
      yabai -m signal --add event=window_created app=iTunes title=iTunes action="killall iTunes"
    '';
  };

  services.spacebar = {
    enable = true;
    package = pkgs.spacebar;
    config = let
      icon_color = "0xFF458588";
      foreground_color = "0xFFA8A8A8";
      background_color = config.services.yabai.config.normal_window_border_color;
    in {
      display = "all";
      position = "top";
      height = barHeight;

      title = "on";

      padding_left = "20";
      padding_right = "20";
      spacing_left = "25";
      spacing_right = "15";

      text_font = ''"NotoMono Nerd Font Mono:Regular:12.0"'';
      icon_font = ''"NotoMono Nerd Font Mono:Regular:14.0"'';

      inherit background_color foreground_color;

      power = "on";
      power_icon_color = icon_color;
      battery_icon_color = icon_color;
      power_icon_strip = "󱐥 󰚥";

      spaces = "on";
      space_icon = "";
      space_icon_color = icon_color;
      spaces_for_all_displays = "off";
      space_icon_strip = "1 2 3 4 5 6 7 8 9 10";

      dnd = "on";
      dnd_icon = "";
      dnd_icon_color = icon_color;

      clock = "on";
      clock_icon = "";
      clock_icon_color = icon_color;
      clock_format = ''"%Y-%m-%d %H:%M:%S"'';

      # right_shell = "on";
      # right_shell_icon = "";
      # right_shell_icon_color = icon_color;
      # right_shell_command = ''echo hi'';
    };
  };

  services.skhd = let
    modifier = "alt";
  in {
    # Don't forget to disable "Secure Keyboard Entry" by opening the terminal application
    enable = true;
    skhdConfig = ''
      # To debug "secure keyboard entry" error:
      # https://github.com/koekeishiya/skhd/issues/48
      # ioreg -l -w 0 | perl -nle 'print $1 if /"kCGSSessionSecureInputPID"=(\d+)/' | uniq | xargs -I{} ps -p {} -o comm=

      # Focus window
      ${modifier} - left : yabai -m window --focus west || yabai -m display --focus west
      ${modifier} - right : yabai -m window --focus east || yabai -m display --focus east
      ${modifier} - up : yabai -m window --focus north || yabai -m display --focus north
      ${modifier} - down : yabai -m window --focus south || yabai -m display --focus south

      # Move managed window
      ${modifier} - space : yabai -m window --toggle split
      ${modifier} + shift - left : yabai -m window --swap west || (yabai -m window --display west && yabai -m display --focus west)
      ${modifier} + shift - right : yabai -m window --swap east || (yabai -m window --display east && yabai -m display --focus east)
      ${modifier} + shift - up : yabai -m window --swap north || (yabai -m window --display north && yabai -m display --focus north)
      ${modifier} + shift - down : yabai -m window --swap south || (yabai -m window --display south && yabai -m display --focus south)

      # Fullscreen
      ${modifier} - f : yabai -m window --toggle native-fullscreen
      ${modifier} + shift - f : yabai -m window --toggle zoom-fullscreen

      # Close
      ${modifier} + shift - q : yabai -m window --close

      # Terminal
      ${modifier} - return : ${pkgs.alacritty}/bin/alacritty

      # Resizing
      ${modifier} + ctrl - left : yabai -m window --resize left:-100:0 || yabai -m window --resize right:-100:0
      ${modifier} + ctrl - right : yabai -m window --resize right:100:0 || yabai -m window --resize left:100:0
      ${modifier} + ctrl - up : yabai -m window --resize top:0:-100 || yabai -m window --resize bottom:0:-100
      ${modifier} + ctrl - down : yabai -m window --resize bottom:0:100 || yabai -m window --resize top:0:100

      # Toggle focus & center window
      ${modifier} + shift - space : yabai -m window --toggle float && yabai -m window --grid 4:4:1:1:2:2 && yabai -m window --focus

      # Focus monitor
      ${modifier} - 1 : yabai -m display --focus 1
      ${modifier} - 2 : yabai -m display --focus 2
      ${modifier} - 3 : yabai -m display --focus 3

      # Send window to monitor
      ${modifier} + shift - 1 : yabai -m window --display 1 && yabai -m display --focus 1
      ${modifier} + shift - 2 : yabai -m window --display 2 && yabai -m display --focus 2
      ${modifier} + shift - 3 : yabai -m window --display 3 && yabai -m display --focus 3

      # Set split direction
      ${modifier} - v : yabai -m window --insert south
      ${modifier} - h : yabai -m window --insert east

      # Reset split ratio
      ${modifier} + ctrl - r : yabai -m window --ratio abs:0.5

      # Restart yabai
      ${modifier} + shift - r : pkill yabai; pkill spacebar

      # Enable/disable yabai tiling
      ${modifier} + shift - e : if [ "$(yabai -m config layout)" == "bsp" ]; then yabai -m config layout float; else yabai -m config layout bsp; fi

      # Toggle dock visibility
      cmd - d: osascript -e 'tell application "System Events" to set the autohide of the dock preferences to not (get the autohide of the dock preferences)'
    '';
  };

  home-manager.users.dorchard = import ./home.nix;

  # System settings
  system.defaults = {
    NSGlobalDomain = {
      # Disable natural scrolling
      "com.apple.swipescrolldirection" = false;

      # Hide menu bar, since spacebar is used instead
      _HIHideMenuBar = true;

      AppleShowAllFiles = true;
    };

    dock = {
      autohide = true;
      tilesize = 16;
      largesize = 128;
      magnification = true;
    };
  };
}
