{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  #programs.alvr = {
  #  enable = true;
  #  openFirewall = true;
  #};

  hardware.steam-hardware.enable = true;

  programs.envision.enable = true;

  services = {
    wivrn = {
      enable = true;
      openFirewall = true;
      defaultRuntime = true;
      autoStart = true;

      config = {
        enable = true;

        json = {
          bitrate = 100000000;
          #encoders = [
          #  {
          #    encoder = "vaapi";
          #    #codec = "av1";
          #    #device = "/dev/dri/renderD128";
          #  }
          #];

          #application = [pkgs.wlx-overlay-s];
        };
      };
    };
  };
}
