{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  services = {
    sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;
      capSysAdmin = true;
    };
  };
}
