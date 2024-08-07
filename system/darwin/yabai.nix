{
  config,
  pkgs,
  ...
}: {
  services.yabai = {
    enable = true;

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
