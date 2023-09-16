{
  services.nix-daemon.enable = true;

  nix = {
    package = pkgs.nix;

    gc = {
      automatic = true;

      interval = {
        Hour = 12;
        Minute = 15;
      };

      options = "--delete-older-than 14d";
      user = "dorchard";
    };
  };
}
