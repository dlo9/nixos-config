{
  pkgs,
  lib,
  ...
}:
with lib; {
  services.nix-daemon.enable = mkDefault true;

  # Tell the daemon to use system certs, so that all trusted certs are used with fetchers
  launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables.NIX_CURL_FLAGS = "--cacert /etc/ssl/certs/ca-certificates.crt";

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
      options = "--delete-old";

      # https://github.com/LnL7/nix-darwin/wiki/Deleting-old-generations#for-multi-user-installation
      user = "root";
    };
  };
}
