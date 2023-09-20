{
  pkgs,
  lib,
  ...
}:
with lib; {
  services.nix-daemon.enable = mkDefault true;

  nix = {
    package = mkDefault pkgs.nix;

    gc = {
      automatic = mkDefault true;

      interval = {
        Hour = 12;
        Minute = 15;
      };

      options = "--delete-older-than 14d";
      user = "dorchard";
    };
  };
}
