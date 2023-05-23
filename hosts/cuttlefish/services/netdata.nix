{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
  config = {
    sops.secrets."services/netdata/health_alarm_notify.conf" = {
      sopsFile = config.sys.secrets.hostSecretsFile;
    };

    services.netdata = {
      enable = true;

      package = pkgs.unstable.netdata;

      config = {
        web = {
          "default port" = "19999";
        };
      };

      configDir = {
        "health_alarm_notify.conf" = config.sops.secrets."services/netdata/health_alarm_notify.conf".path;

        # Enable systemd scraping
        "go.d.conf" = pkgs.writeTextFile "go.d.conf" ''
          modules:
            systemdunits: yes
        '';

        # Enable systemd alerts
        "go.d/systemdunits.conf" = pkgs.writeTextFile "go.d/systemdunits.conf" ''
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
