{
  config,
  pkgs,
  ...
}: {
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
      height = "26";

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

      # right_shell = "on";
      # right_shell_icon = "";
      # right_shell_icon_color = icon_color;
      # right_shell_command = ''echo hi'';
    };
  };
}
