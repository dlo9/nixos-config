{ config, pkgs, lib, ... }:

let
  media-id = 568;
in
{
  config = {
    # Enable nvidia
    sys.graphical.nvidia = true;

    # Add seatd for GPU access
    users.users.david.extraGroups = [ "render" ];

    # Enable steam
    sys.gaming.enable = true;
    security.unprivilegedUsernsClone = true;

    # Enable flatpak for moonlight/subshine
    services.flatpak.enable = true;
    xdg.portal.enable = true;
    xdg.portal.wlr.enable = true;

    # Override sway default
    home-manager.users.david.wayland.windowManager.sway.config.output = {
      HDMI-A-1 = { resolution = "1280x720"; position = "0,0"; };
    };

    # Works (but not performant) with:
    # env WAYLAND_DISPLAY=HEADLESS-1 WLR_BACKENDS=headless WLR_NO_HARDWARE_CURSORS=1 WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman sway --unsupported-gpu
    # env WLR_HEADLESS_OUTPUTS=1 WLR_BACKENDS=headless WLR_RENDERER=pixman sway --unsupported-gpu
    # WLR_RENDER_DRM_DEVICE=/dev/dri/renderD128
    # GBM_BACKEND=nvidia-drm
    # WLR_DRM_DEVICES=/dev/dri/card1
    # GBM_BACKEND=nvidia-drm
    # __GLX_VENDOR_LIBRARY_NAME=nvidia
    # WLR_LIBINPUT_NO_DEVICES=1
    # WLR_NO_HARDWARE_CURSORS=1
    #
    # sudo seatd -u david -g users -l debug
    # env WLR_HEADLESS_OUTPUTS=1 WLR_NO_HARDWARE_CURSORS=1 WLR_RENDER_DRM_DEVICE=/dev/dri/renderD128 sway --unsupported-gpu

    # nv WLR_HEADLESS_OUTPUTS=1 WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_RENDER_DRM_DEVICE=/dev/dri/renderD128 GBM_BACKEND=nvidia-drm dbus-run-session sway --unsupported-gpu

    # Most promising, but wayvnc crashes:
    # env WAYLAND_DISPLAY=HDMI-A-1 WLR_DRM_DEVICES=/dev/dri/card1 WLR_LIBINPUT_NO_DEVICES=1 WLR_BACKENDS=drm sway --unsupported-gpu

    # Testing steps:
    #   1. nvidia-smi pmon
    #   2. sudo seatd -u david -g users -l debug
    #   3. env WLR_DRM_DEVICES=/dev/dri/card1 WLR_BACKENDS=drm,libinput WLR_NO_HARDWARE_CURSORS=1 sway --unsupported-gpu
    #   4. sudo env WAYLAND_DISPLAY=wayland-1 sunshine sunshine.conf

    # Variable docs at: https://gitlab.freedesktop.org/wlroots/wlroots/-/blob/master/docs/env_vars.md
    environment.loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        #exec WAYLAND_DISPLAY=HEADLESS-1 sway
        sway --unsupported-gpu
      fi
    '';

    environment.systemPackages = with pkgs; [
      # Add seatd for GPU access
      seatd

      # VNC
      wayvnc
      novnc
      python310Packages.websockify

      (pkgs.writeScriptBin "novnc-server" ''
        #!/bin/sh

        echo "Starting VNC Server"
        #wayvnc -g -L debug > /tmp/wayvnc &
        /home/david/vnc.sh &

        echo "Starting VNC Client"
        #novnc --web ${pkgs.novnc}/share/webapps/novnc --listen 8080 --vnc localhost:5900 > /tmp/novnc
      '')
    ];

    # Networking
    programs.steam.remotePlay.openFirewall = true;
    networking.firewall = {
      allowedTCPPorts = [
        # VNC
        5900

        # Sunshine
        47984
        47985
        47986
        47987
        47988
        47989
        47990  # Web UI
        48010
      ];

      allowedUDPPorts = [
        # Sunshine
        47998
        47999
        48000
      ];
    };
  };
}
