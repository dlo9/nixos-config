{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
    sys = {
      gaming.enable = false;
      development.enable = false;
      low-power = true;
      networking.authenticateTailscale = true;
    };

    boot.kernelParams = [ "nomodeset" ];
    boot.loader = {
      efi.canTouchEfiVariables = false;
      grub.efiInstallAsRemovable = true;
      grub.useOSProber = false;

      grub.mirroredBoots = [
        { devices = [ "/dev/disk/by-id/usb-Lexar_USB_Flash_Drive_04PRY5BWVCGJ9U83-0:0" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
      ];
    };

    networking.interfaces.enp1s0.useDHCP = true;
    hardware.cpu.intel.updateMicrocode = true;
    hardware.cpu.amd.updateMicrocode = true;

    boot.kernelModules = [
      "kvm-intel"
      "kvm-amd"
    ];

    # Ethernet modules for remote boot login
    boot.initrd.availableKernelModules = [
      "r8169"
      "iwlwifi"
    ];
  };
}
