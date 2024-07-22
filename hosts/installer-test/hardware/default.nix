{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  disk = "/dev/disk/by-path/virtio-pci-0000:03:00.0";
  adminUser = "david";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.disko.nixosModules.disko
    (import ./disks.nix {inherit adminUser disk;})
    ./quirks.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  powerManagement.cpuFreqGovernor = "ondemand";
}
