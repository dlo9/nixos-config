{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
with lib; {
  imports = with inputs.nixos-hardware.nixosModules; [
    common-pc-ssd
    raspberry-pi-4 # TODO: Change to 4

    #./disks.nix
    # ./quirks.nix
    ./generated.nix
  ];

  # From wiki: https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_4
  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  console.enable = false;
  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      fkms-3d.enable = true;
    };

    deviceTree = {
      enable = true;
      #filter = "*rpi-4-*.dtb";
    };
  };

  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = false;
  boot.initrd.systemd.tpm2.enable = false;
  services.tlp.enable = true;

  # Some filesystems aren't needed, and keep the image small
  boot.supportedFilesystems = {
    zfs = mkForce false;
    cifs = mkForce false;
  };

  services.smartd.enable = false;
}
