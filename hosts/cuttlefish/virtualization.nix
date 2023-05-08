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
      # TODO: Try "iommu=pt" for better performance:
      # https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.1/html/installation_guide/appe-configuring_a_hypervisor_host_for_pci_passthrough
      kernelParams = [ "intel_iommu=on" ];
    };

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
      looking-glass-client
    ];

    users.users."${sysCfg.user}".extraGroups = [ "libvirtd" ];
  };
}
