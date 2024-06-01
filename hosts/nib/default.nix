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
    low-power = true;
  };

  zramSwap.enable = true;

  services.smartd.enable = lib.mkForce false;
  virtualisation.docker.enable = lib.mkForce false;
  home-manager.users.david.home.gui.bluetooth.enable = false;

  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];
}
