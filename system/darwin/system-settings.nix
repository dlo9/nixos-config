{
  # System settings
  system.defaults = {
    NSGlobalDomain = {
      # Disable natural scrolling
      "com.apple.swipescrolldirection" = false;

      # Hide menu bar, since spacebar is used instead
      _HIHideMenuBar = true;

      AppleShowAllFiles = true;
    };

    finder.ShowPathbar = true;

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
}
