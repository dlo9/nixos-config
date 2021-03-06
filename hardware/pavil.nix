# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "pool/nixos/root";
      fsType = "zfs";
    };

  fileSystems."/root" =
    {
      device = "pool/home/root";
      fsType = "zfs";
    };

  fileSystems."/home/david" =
    {
      device = "pool/home/david";
      fsType = "zfs";
    };

  fileSystems."/home/david/Games" =
    {
      device = "pool/games";
      fsType = "zfs";
    };

  fileSystems."/boot/efi" =
    {
      device = "/dev/disk/by-uuid/D300-B14E";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/505a2e74-e6a7-44f6-b835-f1bd904acb62"; }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
