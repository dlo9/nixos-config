{ config, lib, pkgs, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.gaming;
in
{
  options.sys.gaming = {
    enable = mkEnableOption "gaming programs" // { default = true; };

    graphical = mkOption {
      type = types.bool;
      default = sysCfg.graphical.enable;
      description = "Weather graphical gaming programs should be installed.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.graphical {
      programs.steam.enable = true;

      environment.systemPackages = with pkgs; [
        # TODO: Try gamehub when available: https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=gamehub
        lutris
      ];
    })

    (mkIf (!cfg.graphical) {
      environment.systemPackages = with pkgs; [
        sysCfg.pkgs.steam-tui
      ];
    })
  ]);
}
