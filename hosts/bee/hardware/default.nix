# Hardware: https://www.minix.us/z83-4-mx
{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  disk = "/dev/disk/by-id/ata-512GB_SSD_CN174BH3902863";
  adminUser = "david";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.disko.nixosModules.disko
    ./generated.nix
    (import ./disks.nix {inherit adminUser disk;})
    ./quirks.nix
  ];

  boot = {
    zfs.requestEncryptionCredentials = [
      "fast"
    ];

    loader = {
      grub.enable = lib.mkForce false;
      systemd-boot.enable = true;
      timeout = lib.mkForce 10;
      efi.canTouchEfiVariables = lib.mkForce false;
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  powerManagement.cpuFreqGovernor = "ondemand";
}
