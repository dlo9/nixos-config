{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  services = {
    wivrn = {
      enable = true;
      openFirewall = true;
      # defaultRuntime = true;
      autoStart = true;
    };
  };
}
