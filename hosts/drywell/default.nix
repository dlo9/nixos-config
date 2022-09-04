{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  config = {
    sys = {
      gaming.enable = false;
    };
  };
}
