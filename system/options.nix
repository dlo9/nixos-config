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
    adminUsers = mkOption {
      type = listOf nonEmptyStr;
      default = [];
    };

    developer-tools.enable = mkEnableOption "developer tools";
    gaming.enable = mkEnableOption "gaming programs";
    graphical.enable = mkEnableOption "graphical programs";
    low-power.enable = mkEnableOption "low power mode";

    font.family = mkOption {
      type = nonEmptyStr;
      default = "NotoSansM Nerd Font Mono";
      # default = "B612";
    };

    font.size = mkOption {
      type = ints.positive;
      default = 14;
    };
  };
}
