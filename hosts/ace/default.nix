{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
    boot.loader = {
      efi.canTouchEfiVariables = false;

      grub.mirroredBoots = [
        { devices = [ "/dev/disk/by-id/ata-KINGSTON_SNS4151S332G_50026B724500626D" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
      ];
    };
  };
}
