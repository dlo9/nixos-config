{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ./hardware
  ];

  sys = {
    gaming.enable = false;
  };

  zramSwap.enable = true;
  nix.distributedBuilds = true;

  services.smartd.enable = lib.mkForce false;
  virtualisation.docker.enable = lib.mkForce false;
  home-manager.users.david.home.gui.bluetooth.enable = false;

  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];
}
