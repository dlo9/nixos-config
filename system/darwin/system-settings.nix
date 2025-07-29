{
  # System settings
  system.defaults = {
    NSGlobalDomain = {
      # Disable natural scrolling
      "com.apple.swipescrolldirection" = false;

      # Show hidden files
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

    WindowManager.EnableStandardClickToShowDesktop = false;
  };

  # Force a public DNS so that tailscale does DOH:
  # https://tailscale.com/kb/1054/dns#global-nameservers
  networking.dns = [
    "9.9.9.9"
    "149.112.112.112"
    "2620:fe::fe"
    "2620:fe::9"
  ];

  networking.knownNetworkServices = [
    "Wi-Fi"
    "Thunderbolt Bridge"
    "AX88179A"
  ];

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
  };
}
