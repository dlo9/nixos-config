{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  services.klipper = {
    enable = true;
    configFile = "/etc/klipper.cfg";
  };

  services.moonraker = {
    enable = true;

    # Allows restart, shutdown, etc.
    # allowSystemControl = true;
  };
  services.fluidd.enable = true;

  # TODO: klipperscreen
}
