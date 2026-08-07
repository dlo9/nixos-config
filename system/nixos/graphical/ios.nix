{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    ios.enable = mkEnableOption "iOS device support";
  };

  config = mkIf config.ios.enable {
    services.usbmuxd.enable = true;

    environment.systemPackages = with pkgs; [
      libimobiledevice
      ifuse # optional, to mount using 'ifuse'
    ];
  };
}
