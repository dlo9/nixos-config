{
  config,
  pkgs,
  lib,
  ...
}: {
  config = {
    # Add seatd for GPU access
    users.users.david.extraGroups = ["render"];

    # Enable flatpak for moonlight/sunshine
    services.flatpak.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      config.common.default = "*";
    };

    environment.systemPackages = with pkgs; [
      sunshine

      # Add seatd for GPU access
      seatd

      # VNC
      #wayvnc
      #novnc
      #python310Packages.websockify

      #(pkgs.writeScriptBin "novnc-server" ''
      #  #!/bin/sh

      #  echo "Starting VNC Server"
      #  #wayvnc -g -L debug > /tmp/wayvnc &
      #  /home/david/vnc.sh &

      #  echo "Starting VNC Client"
      #  #novnc --web ${pkgs.novnc}/share/webapps/novnc --listen 8080 --vnc localhost:5900 > /tmp/novnc
      #'')
    ];

    # Networking
    networking.firewall.interfaces.tailscale0 = {
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
        47990 # Web UI
        48010
      ];

      allowedUDPPorts = [
        # Sunshine
        47998
        47999
        48000
        48010
      ];
    };
  };
}
