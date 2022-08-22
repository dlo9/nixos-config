{ config, lib, pkgs, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.development;
in
{
  options.sys.development = {
    enable = mkEnableOption "development tools" // { default = true; };
  };

  config = mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    programs.adb.enable = true;

    environment.systemPackages = with pkgs // sysCfg.pkgs; [
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
