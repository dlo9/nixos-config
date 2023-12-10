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

    zrepl = {
      interval = mkOption {
        type = nonEmptyStr;
        default = "15m";
      };

      replicateTo = mkOption {
        type = nullOr nonEmptyStr;
        default = null;
      };

      categories = mkOption {
        type = attrsOf (submodule ({name, ...}: {
          options = {
            name = mkOption {
              type = nonEmptyStr;
              default = name;
            };

            prunePolicy = mkOption {
              type = nonEmptyStr;
            };

            replicate = mkOption {
              type = bool;
              default = true;

              apply = value: value && config.zrepl.replicateTo != null;
            };
          };
        }));

        default = {
          # Keep up to 1 year
          long = {
            prunePolicy = "1x1h(keep=all) | 23x1h | 30x1d | 11x30d";
          };

          # Keep up to 1 month
          medium = {
            prunePolicy = "1x1h(keep=all) | 23x1h | 30x1d";
          };

          # Keep up to 1 week
          short = {
            prunePolicy = "1x1h(keep=all) | 23x1h | 6x1d";
          };

          # Keep up to 1 week, but don't replicate
          local = {
            prunePolicy = "1x1h(keep=all) | 23x1h | 6x1d";
            replicate = false;
          };
        };
      };

      filesystems = mkOption {
        type = attrsOf nonEmptyStr;
        default = {};
      };
    };
  };
}
