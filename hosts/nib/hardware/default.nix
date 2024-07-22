# Hardware: https://www.minix.us/z83-4-mx
{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  disk = "/dev/disk/by-id/mmc-BJTD4R_0xddfc5f3b";
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

  nixpkgs.hostPlatform = "x86_64-linux";
  powerManagement.cpuFreqGovernor = "ondemand";
}
