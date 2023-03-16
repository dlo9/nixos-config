{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
    home-manager.users.david.home.gui.bluetooth.enable = false;
    sys.graphical.nvidia = false;

    boot.loader.grub.mirroredBoots = [
      { devices = [ "/dev/disk/by-id/nvme-CT1000P5SSD8_21242F9FEFE5" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
    ];
  };
}
