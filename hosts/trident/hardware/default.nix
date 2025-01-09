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

  #console.enable = false;
  boot.kernelParams = [
    "console=ttyS1,115200n8"
  ];

  #boot.kernelPackages = pkgs.linuxPackages_rpi4;
  nix.settings.max-jobs = 2;

  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      #fkms-3d.enable = true;
    };

    deviceTree = {
      enable = true;
      #filter = mkForce "*-rpi-*.dtb";

      overlays = let
        btt-display = pkgs.fetchFromGitHub {
          owner = "bigtreetech";
          repo = "TFT43-DIP";
          rev = "a4409952502d7e09521454c530ff728bd5856542";
          hash = "sha256-mlkuc5cWJ0qjYV9KgHRTF3JxzOeOe7e++4D54I7p+uY=";
        };
      in [
        #{
        #  name = "rpi-tft43-overlay";
        #  dtboFile = "${btt-display}/gt911_btt_tft43_dip.dtbo";
        #  dtsFile = "${btt-display}/gt911_btt_tft43_dip.dts";
        #}
        #{
        #  name = "vc4-kms-dpi-generic";
        #  dtsFile = pkgs.fetchurl {
        #    url = "https://raw.githubusercontent.com/raspberrypi/linux/refs/heads/rpi-6.6.y/arch/arm/boot/dts/overlays/vc4-kms-dpi-generic-overlay.dts";
        #  };
        #}
      ];
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
