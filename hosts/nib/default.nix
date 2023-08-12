{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware
  ];

  sys = {
    gaming.enable = false;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  powerManagement.cpuFreqGovernor = "ondemand";
}
