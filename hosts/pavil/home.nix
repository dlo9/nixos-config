{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  home.packages = with pkgs; [
    virt-manager # Virtualization management
  ];

  graphical.enable = true;
  developer-tools.enable = true;
}
