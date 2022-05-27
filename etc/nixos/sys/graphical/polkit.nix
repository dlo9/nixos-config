{ config, lib, pkgs, ... }:

with lib;

let
  sysCfg = config.sys;
  parentCfg = sysCfg.graphical;
  cfg = parentCfg.polkit;
in
{
  options.sys.graphical.polkit = {
    enable = mkEnableOption "Polkit (a privilege-escalation tool)" // { default = parentCfg.enable; };

    user = mkOption {
      type = types.nonEmptyStr;
      default = sysCfg.user;
      description = "The user for which polkit will be started when they login";
    };

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

    assertions = [
      {
        #assertion = cfg.enable -> cfg.user != "";
        assertion = cfg.user != "";
        message = "Option user must be a valid user";
      }
    ];
  };
}
