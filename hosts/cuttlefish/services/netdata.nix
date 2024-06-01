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
    systemd.services.netdata = {
      path = [
        # cgroup naming doesn't work without this
        pkgs.kubectl
        pkgs.jq
      ];

      environment = {
        KUBE_CONFIG = "/etc/${config.services.kubernetes.pki.etcClusterAdminKubeconfig}";
      };
    };

    # Give netdata kubectl access
    system.activationScripts.netdata-kubectl-access = ''
      ${pkgs.acl}/bin/setfacl -m "g:${config.services.netdata.group}:r" ${config.services.kubernetes.pki.certs.clusterAdmin.key}
    '';

    services.netdata = {
      enable = true;

      package = pkgs.netdataCloud;

      # View the running config at https://netdata.sigpanic.com/netdata.conf
      config = {
        global = {
          "error log" = "stderr";
        };

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
  };
}
