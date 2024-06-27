{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  hostname,
  ...
}:
with lib; {
  imports = [
    "${inputs.self}/home"
  ];

  home.packages = with pkgs; [
    which
  ];

  programs.atuin.settings.daemon.enabled = false;

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${hostname}.host-ssh-key.pub;
  };
}
