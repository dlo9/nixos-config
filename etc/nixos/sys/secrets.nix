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
      #age.keyFile = "/root/.config/sops/age/keys.txt";
      age.keyFile = "/var/sops-age-keys.txt";
    };
  };
}
