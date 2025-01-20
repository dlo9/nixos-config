{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  services.klipper = {
    enable = true;
    user = "moonraker";
    group = "moonraker";

    # Use a mutable config, under moonraker's config path,
    # so that it can be edited in the UI
    mutableConfig = true;
    mutableConfigFolder = "${config.services.moonraker.stateDir}/config";

    # If missing, download LDO's trident template
    configFile = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/MotorDynamicsLab/LDOVoronTrident/39c4e07d7dedf3674d065c4991ffd35998790f8d/Firmware/printer-leviathan-rev-d.cfg";
      hash = "sha256-QF3MwCO3+SQAVqAeSljh6xO0iVQ3t+aEuFcIXUICpDY=";
    };
  };

  # Required for system control
  security.polkit.enable = true;

  services.moonraker = {
    enable = true;

    # Allows restart, shutdown, etc.
    allowSystemControl = true;

    settings = {
      authorization = {
        trusted_clients = [
          "localhost"
          "192.168.1.0/24"
        ];

        cors_domains = [
          "http://localhost"
          "http://trident"
        ];
      };
    };
  };

  services.fluidd.enable = true;

  networking.firewall.allowedTCPPorts = [
    # Fluidd's nginx
    80
  ];
}
