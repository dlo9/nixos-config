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
    inputs.sops-nix.nixosModules.sops
  ];

  boot.initrd.supportedFilesystems.nfs = true;
  services.dbus.implementation = "broker";

  # Timezone sync (uses geoclue below)
  services.tzupdate.enable = true;
  systemd.services.tzupdate.serviceConfig = {
    Restart = "on-failure";
    RestartSec = 30;
  };

  # Location services
  location.provider = "geoclue2";
  services.geoclue2 = {
    enable = mkDefault true;

    appConfig = {
      "gammastep" = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };

  # Uptime stats
  services.tuptime.enable = true;

  # Autotune
  # services.bpftune doesn't let me override arguments
  #systemd.services.bpftune = {
  #  # Use unstable due to file descriptor leak: https://github.com/oracle/bpftune/issues/102
  #  script = "${pkgs.unstable.bpftune}/bin/bpftune -ds";
  #  wantedBy = ["multi-user.target"];
  #};

  # POSIX shell implementation
  environment.binsh = "${pkgs.dash}/bin/dash";

  programs.fish.enable = true;
  # Fish enables this by default, which results in slow builds:
  # https://discourse.nixos.org/t/slow-build-at-building-man-cache/52365
  documentation.man.cache.enable = false;

  environment.shells = [config.programs.fish.package];

  services.kmscon = {
    enable = false;
    hwRender = true;
    fonts = [
      {
        name = config.font.family;
        package = pkgs.nerd-fonts.noto;
      }
    ];
  };

  services.journald.extraConfig = ''
    # Maximum total journal size
    SystemMaxUse=500M

    # Maximum journal size in temporary storage
    RuntimeMaxUse=128M

    # Maximum time to retain log files
    MaxFileSec=1year
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = mkDefault "22.05"; # Did you read the comment?
}
