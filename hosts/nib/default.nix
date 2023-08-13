{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware
  ];

  sys = {
    gaming.enable = false;
  };
}
