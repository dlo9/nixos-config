{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  # Tell the daemon to use system certs, so that all trusted certs are used with fetchers
  launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables.NIX_CURL_FLAGS = "--cacert /etc/ssl/certs/ca-certificates.crt";

  nix = mkIf config.nix.enable {
    package = mkDefault pkgs.nix;

    optimise = {
      automatic = true;
      interval = {
        Hour = 12;
        Minute = 0;
        Weekday = 3; # Wednesday
      };
    };

    gc = {
      automatic = mkDefault true;

      interval = {
        Hour = 12;
        Minute = 15;
        Weekday = 3; # Wednesday
      };

      # darwin-rebuild --list-generations
      options = "--delete-old";
    };
  };
}
