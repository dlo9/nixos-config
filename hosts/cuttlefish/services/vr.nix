{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  programs.alvr = {
    # https://github.com/alvr-org/ALVR/issues/2014#issuecomment-2509734136
    enable = false;
    openFirewall = true;
  };

  hardware.steam-hardware.enable = true;

  programs.envision.enable = true;

  systemd.user.services.wivrn.path = with pkgs; [
    pulseaudio # For changing volume with wlx-overlay-s
  ];

  #services = {
  #  wivrn = {
  #    enable = true;
  #    openFirewall = true;
  #    defaultRuntime = true;
  #    autoStart = true;

  #    config = {
  #      enable = true;

  #      json = {
  #        bitrate = 10000000; # 10 MiB
  #        encoders = [
  #          {
  #            encoder = "vaapi";
  #            #codec = "av1";
  #            codec = "h265";
  #            device = "/dev/dri/renderD128";
  #          }
  #        ];

  #        application = [pkgs.unstable.wlx-overlay-s];
  #      };
  #    };
  #  };
  #};
}
