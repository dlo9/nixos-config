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
        lutris
        gamehub
        moonlight-qt
      ];
    })
  ]);
}
