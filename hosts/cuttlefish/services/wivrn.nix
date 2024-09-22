{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./wivrn/module.nix
  ];

  services = {
    wivrn = {
      enable = true;
      package = pkgs.dlo9.wivrn;
      openFirewall = true;
      # defaultRuntime = true;
      autoStart = true;
    };
  };
}
