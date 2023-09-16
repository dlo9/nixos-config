{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
with types;
with builtins; {
  options = {
    admin-users = mkOption {
      type = listOf nonEmptyStr;
      default = [];
    };

    developer-tools.enable = mkEnableOption "developer tools";
    gaming.enable = mkEnableOption "gaming programs";
    graphical.enable = mkEnableOption "graphical programs";
    low-power.enable = mkEnableOption "low power mode";
  };
}
