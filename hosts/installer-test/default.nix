{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  imports = [
    ./hardware
  ];

  sys = {
    gaming.enable = false;
    # graphical.enable = false;
  };

  boot.postBootCommands = ''
    chown david:users /home/david
  '';
}
