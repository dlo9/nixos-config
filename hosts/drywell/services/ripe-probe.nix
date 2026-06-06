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
        "/services/ripe/etc:/etc/ripe-atlas"
        "/services/ripe/spool:/var/spool/ripe-atlas"
        "/services/ripe/run:/run/ripe-atlas"
      ];

      extraOptions = [
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=DAC_OVERRIDE"
        "--cap-add=FOWNER"
        "--cap-add=KILL"
        "--cap-add=NET_RAW"
        "--cap-add=SETGID"
        "--cap-add=SETUID"
      ];
    };
  };
}
