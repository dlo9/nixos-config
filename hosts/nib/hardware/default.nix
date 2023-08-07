{ config, inputs, lib, pkgs, modulesPath, ... }:

let
  diskId = "/dev/disk/by-id/mmc-BJTD4R_0xddfc5f3b";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.disko.nixosModules.disko
    # ./generated.nix
  ];

  disko.devices = import ./disks.nix {
    inherit diskId;
    adminUser = "david";
  };

  boot.loader.grub = {
    devices = [ diskId ];
    efiSupport = true;
    efiInstallAsRemovable = false;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
