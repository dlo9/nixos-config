{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
    networking.interfaces.wlo1.useDHCP = true;

    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; efiSysMountPoint = "/boot/efi"; path = "/boot/efi/EFI"; }
    ];

    # Bluetooth
    services.blueman.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    # Enable A2DP Sink: https://nixos.wiki/wiki/Bluetooth
    hardware.bluetooth.settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };

    # Auto-switch to new bluetooth devices
    hardware.pulseaudio.extraConfig = "
      load-module module-switch-on-connect
    ";
  };
}
