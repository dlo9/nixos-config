{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  services.go2rtc = {
    enable = true;

    settings = let
      camera = format: size: "ffmpeg:device?video=/dev/video0&input_format=${format}&video_size=${size}";

      # Rotate with ffmpeg, requires transcoding (50% CPU)
      #camera = format: size: "ffmpeg:device?video=/dev/video0&input_format=${format}&video_size=${size}#video=${format}#rotate=180";
    in {
      # See docs for options: https://cdn.shopify.com/s/files/1/0580/2262/5458/files/A3369_WEB_Manual_V01_202111220.pdf
      streams.c200-h264-large = camera "h264" "2560x1440";
      streams.c200-h264-medium = camera "h264" "1920x1080";
      streams.c200-h264-small = camera "h264" "1280x720";

      streams.c200-mjpeg-large = camera "mjpeg" "2560x1440";
      streams.c200-mjpeg-medium = camera "mjpeg" "1920x1080";
      streams.c200-mjpeg-small = camera "mjpeg" "1280x720";

      api.origin = "*"; # CORS anywhere

      # https://github.com/AlexxIT/go2rtc?tab=readme-ov-file#module-webrtc
      webrtc.candidates = ["stun:8555"];
    };
  };

  systemd.services.go2rtc.serviceConfig.Restart = "always";

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
