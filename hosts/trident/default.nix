{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:
with lib; {
  imports = [
    ./hardware
    ./services
  ];

  config = {
    # Users
    users.users.david.name = "pi";
    # adminUsers = mkForce ["pi"];
    home-manager.users.david = import ./home.nix;

    nix.distributedBuilds = true;
    system.stateVersion = "24.11";
  };
}
