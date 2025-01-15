{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  services.go2rtc = {
    enable = true;
    settings = {
      streams.c200 = "ffmpeg:device?video=/dev/video0&input_format=h264&video_size=2560x1440";
      api.origin = "*"; # CORS anywhere
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      1984 # API/webpage
      8555 # webrtc
    ];

    allowedUDPPorts = [
      8555 # webrtc
    ];
  };
}
