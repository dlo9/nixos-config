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

      package = (pkgs.netdata.overrideAttrs
        (oldAttrs: rec {
          postFixup =
            oldAttrs.postFixup
            + ''
              wrapProgram $out/libexec/netdata/plugins.d/cgroup-name.sh --prefix PATH : ${lib.makeBinPath [pkgs.kubectl]}
            '';
        }))
      .override {withCloud = true;};

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
