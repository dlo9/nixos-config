{ config, lib, pkgs, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.graphical.polkit;
in
{
  options.sys.graphical.polkit = {
    enable = mkEnableOption "Polkit (a privilege-escalation tool)" // { default = true; };

    user = mkOption {
      type = types.nonEmptyStr;
      default = sysCfg.user;
      description = "The user for which polkit will be started when they login";
    };

    package = mkOption {
      description = "The polkit package to use.";
      type = types.path;
      default = pkgs.polkit_gnome;
      #defaultText = literalExpression "pkgs.polkit_gnome";
    };
  };

  config = mkIf (sysCfg.graphical.enable && cfg.enable) {
    environment.systemPackages = [ cfg.package ];

    system.activationScripts = {
      autoStartPolkit = ''
        echo "exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" > /home/${cfg.user}/.config/sway/config.d/autostart_polkit
      '';
    };

    assertions = [
      {
        #assertion = cfg.enable -> cfg.user != "";
        assertion = cfg.user != "";
        message = "Option user must be a valid user";
      }
    ];
  };
}
