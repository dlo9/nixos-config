{
  config,
  lib,
  pkgs,
  hostname,
  inputs,
  osConfig,
  ...
}:
with lib; {
  imports = [
    "${inputs.self}/home"
  ];

  home.packages = with pkgs; [
    virt-manager # Virtualization management
  ];

  graphical.enable = true;
  developer-tools.enable = true;

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${hostname}.david-ssh-key.pub;
  };
}
