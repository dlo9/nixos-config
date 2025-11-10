{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  moonrakerConfig = "${config.services.moonraker.stateDir}/config/moonraker.cfg";
in {
  services.klipper = {
    enable = true;
    user = "moonraker";
    group = "moonraker";

    package = pkgs.klipper.overrideAttrs (oldAttrs: let
      z-calibration = pkgs.fetchFromGitHub {
        owner = "protoloft";
        repo = "klipper_z_calibration";
        rev = "v1.1.3";
        sha256 = "sha256-WWP0LqhJ3ET4nxR8hVpq1uMOSK+CX7f3LXjOAZbRY8c=";
      };
    in {
      postInstall = ''
        # Call the original postInstall step
        ${oldAttrs.postInstall or ""}

        # Add plugins
        chmod +w $out/lib/klipper/extras

        cp ${z-calibration}/z_calibration.py $out/lib/klipper/extras/z_calibration.py
      '';
    });

    # Use a mutable config, under moonraker's config path,
    # so that it can be edited in the UI
    mutableConfig = true;
    configDir = "${config.services.moonraker.stateDir}/config";

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
          "192.168.0.0/16"
          "100.64.0.0/10" # Tailscale
        ];

        cors_domains = [
          "http://localhost"
          "http://trident"
          "*://trident.sigpanic.com"
        ];
      };

      "include ${moonrakerConfig}" = {};
    };
  };

  # Ensure the moonraker config exists, or else moonraker won't start
  systemd.services.moonraker.serviceConfig.ExecStartPre = "-${pkgs.writeShellApplication {
    name = "create-moonraker-config";

    text = ''
      if [ ! -e "${moonrakerConfig}" ]; then
        touch "${moonrakerConfig}"
        chown ${config.services.moonraker.user}:${config.services.moonraker.group} "${moonrakerConfig}"
      fi
    '';
  }}/bin/create-moonraker-config";

  services.fluidd = {
    enable = true;
    nginx.extraConfig = ''
      client_max_body_size 100M;
    '';
  };

  networking.firewall.allowedTCPPorts = [
    # Fluidd's nginx
    80
  ];
}
