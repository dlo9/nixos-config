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
    #boot.binfmt.emulatedSystems = [ "aarch64-linux i686-linux x86_64-linux" ];
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    programs.adb.enable = true;

    environment.systemPackages = with pkgs // sysCfg.pkgs; [
      cargo
      qemu_kvm
      OVMF
      libvirt
      clang # C compiler
      jq
      yq
    ];

    # Allow running unpatched binaries, including vscode-serer
    programs.nix-ld.enable = true;
    environment.sessionVariables = {
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.stdenv.cc.cc ];
      NIX_LD = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2";
    };
  };
}
