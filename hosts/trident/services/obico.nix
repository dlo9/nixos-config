{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
    configFile = "/etc/obico.cfg";

    defaultConfigContents = builtins.toFile "obico.cfg" ''
      [server]
      url = https://obico.sigpanic.com

      [moonraker]
      host = localhost
    '';
in {
  virtualisation.oci-containers.containers.obico = {
    image = "ghcr.io/thespaghettidetective/moonraker-obico:latest";
    volumes = [ "${configFile}:/opt/printer_data/config/moonraker-obico.cfg" ];
    extraOptions = [ "--privileged" ];
    user = "root:root";
  };

  # Create the config file
  # This must be writable because a random auth key is used when connecting to the server
  #
  # After first boot, run this to connect:
  # sudo podman exec -it obico /opt/venv/bin/python -m moonraker_obico.link -c /opt/printer_data/config/moonraker-obico.cfg
  systemd.services.${config.virtualisation.oci-containers.containers.obico.serviceName}.serviceConfig.ExecStartPre = let
  in "-${pkgs.writeShellApplication {
    name = "create-obico-config";

    text = ''
      if [ ! -e "${configFile}" ]; then
        cp "${defaultConfigContents}" "${configFile}"
        chmod u+w "${configFile}"
      fi
    '';
  }}/bin/create-obico-config";
}
