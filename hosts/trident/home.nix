{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:
with lib; {
  imports = [
    "${inputs.self}/home"
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    devenv
  ];

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${osConfig.networking.hostName}.pi-ssh-key.pub;
  };
}
