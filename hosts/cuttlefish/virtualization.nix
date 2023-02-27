{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  sysCfg = config.sys;
in
{
  config = {
    boot = {
      kernelModules = [ "vfio-pci" ];
      kernelParams =  [ "intel_iommu=on" ];
    };

    networking.bridges.bridge-lan.interfaces = [ "enp5s0f0" ];

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMFFull.override {
              secureBoot = true;
              tpmSupport = true;
              csmSupport = true;
            }).fd
          ];
        };
      };
    };

    programs.dconf.enable = true;
    environment.systemPackages = with pkgs; [
      virt-manager
    ];

    users.users."${sysCfg.user}".extraGroups = [ "libvirtd" ];
  };
}
