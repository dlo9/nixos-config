{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sys.development;
in
{
  options.sys.development = {
    enable = mkEnableOption "development tools" // { default = true; };
  };

  config = mkIf cfg.enable {
    #boot.binfmt.emulatedSystems = [ "aarch64-linux i686-linux x86_64-linux" ];
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    programs.adb.enable = true;

    environment.systemPackages = with pkgs; [
      cargo
      qemu_kvm
      OVMF
      libvirt
      clang # C compiler
      jq
      yq-go
    ];

    # Allow running unpatched binaries, including vscode-serer
    programs.nix-ld.enable = true;
  };
}
