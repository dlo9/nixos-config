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

      # darwin-rebuild --list-generations
      options = "--delete-older-than 7d";

      # https://github.com/LnL7/nix-darwin/wiki/Deleting-old-generations#for-multi-user-installation
      user = "root";
    };
  };
}
