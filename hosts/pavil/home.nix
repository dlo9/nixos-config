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
    #(orca-slicer.overrideAttrs (finalAttrs: previousAttrs: {
    #  # TODO: Remove once merged:
    #  # https://github.com/NixOS/nixpkgs/pull/360219/files
    #  cmakeFlags = lib.remove "-DFLATPAK=1" previousAttrs.cmakeFlags or [ ];
    #}))
    freecad
  ];

  # SSH
  home.file = {
    ".ssh/id_ed25519.pub".text = osConfig.hosts.${osConfig.networking.hostName}.david-ssh-key.pub;
  };

  programs.alacritty.settings.font.size = 11.0;
}
