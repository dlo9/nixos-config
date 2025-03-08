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

    mainAdmin = mkOption {
      type = nullOr nonEmptyStr;

      # Defaults to the first listed admin user
      default =
        if ((builtins.length config.adminUsers) == 1)
        then (builtins.elemAt config.adminUsers 0)
        else null;
    };

    developer-tools.enable = mkEnableOption "developer tools";
    gaming.enable = mkEnableOption "gaming programs";
    graphical.enable = mkEnableOption "graphical programs";
    fix-efi.enable = mkEnableOption "fix EFI permissions" // {default = true;};

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

          # Keep up to 1 day
          day = "1x1h(keep=all) | 23x1h";
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

        default = {};
      };
    };
  };
}
