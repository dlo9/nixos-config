{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with builtins;
with lib; let
in {
  config = {
    virtualisation.oci-containers.containers.ripe-probe = {
      image = "jamesits/ripe-atlas";

      environment.RXTXRPT = "yes";

      volumes = [
        "/services/ripe/etc:/var/atlas-probe/etc"
        "/services/ripe/status:/var/atlas-probe/status"
      ];

      extraOptions = [
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=SETUID"
        "--cap-add=SETGID"
        "--cap-add=DAC_OVERRIDE"
        "--cap-add=NET_RAW"
      ];
    };
  };
}
