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

  # Timezone
  services.localtimed.enable = true;

  # Location services
  services.geoclue2 = {
    enable = true;

    appConfig = {
      "gammastep" = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };

  # POSIX shell implementation
  environment.binsh = "${pkgs.dash}/bin/dash";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}
