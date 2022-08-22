{ config, lib, pkgs, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.development;
in
{
  options.sys.gaming = {
    enable = mkEnableOption "development tools" // { default = true; };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs // cfg.pkgs; [
      git
      cargo
      qemu_kvm
      OVMF
      libvirt
      clang # C compiler
      jq
      yq
    ];
  };
}
