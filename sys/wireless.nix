{ config, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.wireless;
in
{
  options.sys.wireless = {
    enable = mkEnableOption "wireless networking" // { default = true; };
  };

  config = mkIf cfg.enable {
    sops.secrets.wireless-env = { };

    networking.wireless = {
      enable = true;
      userControlled.enable = true;
      environmentFile = config.sops.secrets.wireless-env.path;
      networks = {
        BossAdams.psk = "@BOSS_ADAMS@";
        "pretty fly for a wifi".psk = "@PRETTY_FLY_FOR_A_WIFI@";
        qwertyuiop.psk = "@QWERTYUIOP@";
        LGFAK.psk = "@LGFAK@";
      };
    };
  };
}
