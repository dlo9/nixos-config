{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  parentCfg = config.sys.graphical;
  cfg = parentCfg.polkit;
in {
  options.sys.graphical.polkit = {
    enable = mkEnableOption "Polkit (a privilege-escalation tool)" // {default = parentCfg.enable;};

    # With 22.05
    #package = lib.options.mkPackageOption pkgs "polkit" {
    package = mkOption {
      description = "The polkit package to use.";
      type = types.path;
      default = pkgs.polkit_gnome;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      (pkgs.writeShellScriptBin "polkit-agent" "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1")
    ];
  };
}
