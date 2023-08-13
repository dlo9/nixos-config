{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware
  ];

  sys = {
    gaming.enable = false;
  };

  services.smartd.enable = lib.mkForce false;
}
