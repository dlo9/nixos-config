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
      snapInterval = mkOption {
        type = nonEmptyStr;
        default = "15m";
      };

      remote = mkOption {
        type = nullOr nonEmptyStr;
        default = null;
      };

      retentionPolicies = mkOption {
        type = attrsOf nonEmptyStr;

        default = {
          # Keep up to 1 year
          year = "1x1h(keep=all) | 23x1h | 30x1d | 11x30d";

          # Keep up to 1 month
          month = "1x1h(keep=all) | 23x1h | 30x1d";

          # Keep up to 1 week
          week = "1x1h(keep=all) | 23x1h | 6x1d";
        };
      };

      filesystems = mkOption {
        type = attrsOf (submodule ({
          name,
          config,
          ...
        }: {
          options = {
            name = mkOption {
              type = nonEmptyStr;
              default = name;
            };

            local = mkOption {
              type = nullOr nonEmptyStr;
              default = config.both;
            };

            remote = mkOption {
              type = nullOr nonEmptyStr;
              default = config.both;
            };

            both = mkOption {
              type = nullOr nonEmptyStr;
              default = "unmanaged";
            };
          };
        }));
      };
    };
  };
}
