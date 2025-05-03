# Hardware: https://www.minix.us/z83-4-mx
{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  disk = "/dev/disk/by-id/ata-SAMSUNG_MZNLH128HBHQ-000H1_S4HENX0N984856";
  adminUser = "david";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.disko.nixosModules.disko
    (import ./disks.nix {inherit adminUser disk;})
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  powerManagement.cpuFreqGovernor = "ondemand";

  # TODO: undo this after installing, it fixes a boot device conflict
  fix-efi.enable = false;
}
