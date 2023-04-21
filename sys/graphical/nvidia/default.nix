{ config, pkgs, lib, ... }:

with lib;

let
  unlock = import ./unlock.nix;
in
{
  options.sys.graphical = {
    nvidia = mkEnableOption "nvidia GPU" // { default = false; };
  };

  config = {
    # Required to remedy weird crash when using nvidia in docker
    # systemd.enableUnifiedCgroupHierarchy = false;

    # https://nixos.wiki/wiki/Chromium#Enabling_native_Wayland_support
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # Nvidia driver
    services.xserver.videoDrivers = [ "nvidia" ];

    # Enable nvidia DRM
    hardware = {
      nvidia = {
        modesetting.enable = true;
        package = unlock {
          inherit config lib;
          patchNvenc = true;
          patchNvfbc = true;
        };
      };

      opengl.extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl

        # TODO: the following test still doesn't work
        # nix-shell -p libva-utils --run vainfo
        nvidia-vaapi-driver
      ];
    };
  };
}
