{
  config,
  pkgs,
  lib,
  isLinux,
  ...
}:
with lib; {
  options.dms = {
    settings = mkOption {
      type = types.attrs;
      default = {};

      description = ''
        Declarative `~/.config/DankMaterialShell/settings.json`.

        Left empty (the default) DMS owns the file and its settings UI writes
        to it. Set anything and home-manager links it read-only out of the
        store instead; DMS handles that by putting the settings UI in read-only
        mode rather than erroring. Unset keys keep their defaults.

        `dms ipc call settings get` dumps the running config to copy in here.
      '';

      example = literalExpression ''
        {
          lockTimeout = 300;
          acMonitorTimeout = 600;
          acSuspendTimeout = 900;
        }
      '';
    };
  };

  config = mkIf (config.graphical.enable && isLinux) {
    xdg.configFile."DankMaterialShell/settings.json" = mkIf (config.dms.settings != {}) {
      source = (pkgs.formats.json {}).generate "dms-settings.json" config.dms.settings;
    };
  };
}
