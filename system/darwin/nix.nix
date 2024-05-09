{
  pkgs,
  lib,
  ...
}:
with lib; {
  services.nix-daemon.enable = mkDefault true;

  nix = {
    package = mkDefault pkgs.nix;

    settings.auto-optimise-store = true;

    gc = {
      automatic = mkDefault true;

      interval = {
        Hour = 12;
        Minute = 15;
      };

      options = "--delete-older-than 7d";
      user = "dorchard";
    };
  };
}
