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
      # See docs for options: https://cdn.shopify.com/s/files/1/0580/2262/5458/files/A3369_WEB_Manual_V01_202111220.pdf
      streams.c200-h264-large = "ffmpeg:device?video=/dev/video0&input_format=h264&video_size=2560x1440";
      streams.c200-mjpeg-large = "ffmpeg:device?video=/dev/video0&input_format=mjpeg&video_size=2560x1440";
      streams.c200-h264-medium = "ffmpeg:device?video=/dev/video0&input_format=h264&video_size=1920x1080";
      streams.c200-mjpeg-medium = "ffmpeg:device?video=/dev/video0&input_format=mjpeg&video_size=1920x1080";
      streams.c200-h264-small = "ffmpeg:device?video=/dev/video0&input_format=h264&video_size=1280x720";
      streams.c200-mjpeg-small = "ffmpeg:device?video=/dev/video0&input_format=mjpeg&video_size=1280x720";

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
