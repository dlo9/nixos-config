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

  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    # virt-manager # Virtualization management
    rustdesk
    sidequest
    nvtopPackages.amd # GPU monitoring
    amdgpu_top
    orca-slicer
  ];

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${osConfig.networking.hostName}.david-ssh-key.pub;
  };

  programs.alacritty.settings.font.size = 11.0;
}
