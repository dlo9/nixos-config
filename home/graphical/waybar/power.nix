{
  pkgs,
  lib,
  wofi,
}:
pkgs.writeShellApplication {
  name = "power.sh";
  runtimeInputs = [wofi];
  text = lib.readFile ./power.sh;
}
