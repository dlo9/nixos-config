{
  config,
  lib,
  ...
}:
with lib; let
  enabled = config.services.desktopManager.plasma6.enable;
in {
  services.xserver.enable = mkDefault enabled;

  services.displayManager = {
    enable = mkDefault enabled;
    autoLogin.user = mkDefault config.mainAdmin;
    defaultSession = "plasmax11"; # Wayland gives a black screen
    sddm = {
      enable = mkDefault enabled;
      wayland.enable = mkDefault enabled; # Use waycheck to check wayland features
      autoLogin.relogin = mkDefault true;
    };
  };
}
