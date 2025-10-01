{
  config,
  pkgs,
  lib,
  ...
}: {
  # Hide menu bar, since spacebar is used instead
  system.defaults.NSGlobalDomain._HIHideMenuBar = config.services.spacebar.enable;

  services.sketchybar = {
    enable = config.services.aerospace.enable;
  };

  fonts.packages = with pkgs; [
    # For application icons
    sketchybar-app-font
  ];

  launchd.user.agents.spacebar.serviceConfig = lib.mkIf config.services.spacebar.enable {
    StandardErrorPath = "/tmp/spacebar.err.log";
    StandardOutPath = "/tmp/spacebar.out.log";
  };

  services.spacebar = let
    isFullscreen = "${pkgs.writeShellApplication {
      name = "is-fullscreen";
      runtimeInputs = with pkgs; [yabai jq];
      text = ''
        yabai -m query --windows | jq -r '.[] | select(."has-focus") | ."has-fullscreen-zoom" | if . then "Fullscreen" else "" end'
      '';
    }}/bin/is-fullscreen";
  in {
    enable = config.services.yabai.enable;
    package = pkgs.spacebar;

    config = let
      icon_color = "0xFF458588";
      foreground_color = "0xFFA8A8A8";
      background_color = config.services.yabai.config.normal_window_border_color;
    in {
      display = "all";
      position = "top";
      height = "26";

      title = "off";

      padding_left = "20";
      padding_right = "20";
      spacing_left = "25";
      spacing_right = "15";

      text_font = ''"${config.font.family}:Regular:${builtins.toString config.font.size}"'';
      icon_font = ''"${config.font.family}:Regular:${builtins.toString config.font.size}"'';

      inherit background_color foreground_color;

      power = "on";
      power_icon_color = icon_color;
      battery_icon_color = icon_color;
      power_icon_strip = "󰁹 󰚥";

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

      # See extraConfig comment
      #center_shell = "on";
      center_shell_command = isFullscreen;
    };

    # Put some extra config options at the end. center_shell MUST go after title,
    # but the modules's automatic conversion sorts alphabetically, which breaks it
    # Further, there must be a newline because this option doesn't append correctly
    # extraConfig = ''

    #   spacebar -m config center_shell on
    # '';
  };
}
