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

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${osConfig.networking.hostName}.david-ssh-key.pub;
  };
}
