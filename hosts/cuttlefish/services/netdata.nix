{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; {
  config = {
    services.netdata = {
      enable = true;

      config = {
        web = {
          "default port" = "19999";
        };
      };

      configDir = {
        "health_alarm_notify.conf" = config.sops.secrets."netdata-health_alarm_notify.conf".path;

        # Enable systemd scraping
        "go.d.conf" = pkgs.writeText "go.d.conf" ''
          modules:
            systemdunits: yes
        '';

        # Enable systemd alerts
        "go.d/systemdunits.conf" = pkgs.writeText "go.d/systemdunits.conf" ''
          jobs:
            - name: service-units
              include:
                - '*.service'
        '';
      };
    };

    # services.caddy.virtualHosts.netdata = {
    #   useACMEHost = "sigpanic.com";
    #   serverAliases = [ "netdata.sigpanic.com" ];
    #   extraConfig = ''
    #     reverse_proxy http://localhost:19999
    #   '';
    # };
  };
}
