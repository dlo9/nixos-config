{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  imports = [
    ./networking
    ./graphical
    ./zfs

    ./admin.nix
    ./boot.nix
    ./developer-tools.nix
    ./gaming.nix
    ./hardware.nix
    ./nix.nix
    ./users.nix

    inputs.home-manager.nixosModules.home-manager
  ];

  boot.initrd.supportedFilesystems.nfs = true;
  services.dbus.implementation = "broker";

  # Timezone sync (uses geoclue below)
  services.tzupdate.enable = true;

  # Location services
  location.provider = "geoclue2";
  services.geoclue2 = {
    enable = mkDefault true;
    submissionUrl = "https://api.beacondb.net/v1/geolocate";
    geoProviderUrl = "https://api.beacondb.net/v1/geolocate";

    appConfig = {
      "gammastep" = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };

  # Uptime stats
  services.tuptime.enable = true;

  # POSIX shell implementation
  environment.binsh = "${pkgs.dash}/bin/dash";

  programs.fish.enable = true;
  # Fish enables this by default, which results in slow builds:
  # https://discourse.nixos.org/t/slow-build-at-building-man-cache/52365
  documentation.man.generateCaches = false;

  environment.shells = [pkgs.fish];

  services.kmscon = {
    enable = false;
    hwRender = true;
    autologinUser = mkDefault config.mainAdmin;
    fonts = [
      {
        name = config.font.family;
        package = (pkgs.nerdfonts.override {
          fonts = [
            "Noto"
          ];
        });
      }
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = mkDefault "22.05"; # Did you read the comment?
}
