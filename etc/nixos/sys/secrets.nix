{ config, pkgs, lib, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.secrets;
in
{
  options.sys.secrets = {
    enable = mkEnableOption "secrets management" // { default = true; };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../secrets.yaml;
      # This file must be in the filesystems mounted within the initfs.
      # I put it in the root filesystem since that's mounted first.
      age.keyFile = "/var/sops-age-keys.txt";
    };
  };
}
