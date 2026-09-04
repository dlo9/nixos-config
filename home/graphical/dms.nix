{
  config,
  pkgs,
  lib,
  isLinux,
  osConfig,
  ...
}:
with lib; {
  options.dms = {
    enable =
      mkEnableOption "DankMaterialShell"
      // {default = osConfig.dms.enable;};

    settings = mkOption {
      type = types.attrs;
      default = {};

      description = ''
        Declarative `~/.config/DankMaterialShell/settings.json`.

        Left empty (the default) DMS owns the file and its settings UI writes to
        it, which is the sane starting point -- the schema is large and mostly
        discovered through the UI.

        Set anything here and home-manager links the file read-only out of the
        store instead. DMS handles that deliberately: it polls whether the file
        is writable (`SettingsData._checkSettingsWritable`) and, when it isn't,
        keeps running with the settings UI in read-only mode rather than
        erroring. Unset keys keep their defaults, so partial attrsets are fine.

        Once the shell is dialled in, `dms ipc call settings get` /
        `~/.config/DankMaterialShell/settings.json` is the thing to copy in
        here to make the desktop reproducible again.
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

  config = mkIf (config.dms.enable && isLinux) {
    xdg.configFile."DankMaterialShell/settings.json" = mkIf (config.dms.settings != {}) {
      source = (pkgs.formats.json {}).generate "dms-settings.json" config.dms.settings;
    };
  };
}
