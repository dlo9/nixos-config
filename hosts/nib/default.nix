{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  # imports = [
  # ];

  nixpkgs.hostPlatform = "x86_64-linux";
  powerManagement.cpuFreqGovernor = "ondemand";
}
