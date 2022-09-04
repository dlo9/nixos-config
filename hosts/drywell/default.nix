{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
    sys = {
      gaming.enable = false;
      development.enable = false;
      graphical.enable = false;
      # TODO: kubernetes
    };

    boot.kernelParams = [ "nomodeset" ];
    boot.loader = {
      grub.mirroredBoots = [
        { devices = [ "/dev/disk/by-id/nvme-Force_MP500_17037932000122530025" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
      ];
    };

    networking.interfaces.enp1s0.useDHCP = true;

    # Ethernet modules for remote boot login
    boot.initrd.kernelModules = [
      "r8169"
    ];
  };
}
