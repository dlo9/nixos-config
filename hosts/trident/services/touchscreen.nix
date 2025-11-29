{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  # Disable getty (tty console) to avoid race condition
  # between getty and cage for claiming the VT
  console.enable = false;

  # Seatd is better than logind for headless services
  services.seatd.enable = true;
  users.users.david.extraGroups = [ "seat" ];

  services.cage = {
    enable = true;
    program = "${pkgs.dlo9.klipperscreen}/bin/KlipperScreen";
    user = "pi";

    environment = {
      WLR_LIBINPUT_NO_DEVICES = "1"; # boot up even if no mouse/keyboard connected
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
  };

  # Rotate the screen after cage starts
  systemd.services."cage-tty1" = let
    # Cage has a race condition and fails to start a user session without this
    requirements = ["user.slice" "user@1000.service" "systemd-user-sessions.service" "dbus.socket" "systemd-udev-settle.service" "seatd.service"];
  in rec {
    requires = requirements;
    after = requirements;

    # Fix issue with cage not disaplaying on startup. But don't use .device units, since they won't become active if the device is
    # created before systemd
    unitConfig.ConditionPathExists = ["/dev/dri/card0"];

    serviceConfig = {
      TimeoutStartSec = "10s";

      # Sometimes cage doesn't start properly and then exists successfully, but we still want it to restart
      Restart = "always";
      RestartForceExitStatus = [ 0 ];

      # Use seatd
      Environment = [ "LIBSEAT_BACKEND=seatd" ];

      ExecStartPost = "-${pkgs.writeShellApplication {
        name = "rotate-display";

        runtimeInputs = with pkgs; [
          wlr-randr
          jq
        ];

        text = ''
          # Wait until the session exists
          until [[ -e "$XDG_RUNTIME_DIR/wayland-0" ]]; do
            sleep 1
          done

          display="$(wlr-randr --json | jq -r '.[].name')"
          echo "Rotating display $display"
          wlr-randr --output "$display" --transform 180
        '';
      }}/bin/rotate-display";
    };
  };

  # Enable wireless control
  # wpa_supplicant sometimes fails to connect on boot, use network-manager instead.
  # This also enables adhoc networking via the touchscreen
  networking.networkmanager.enable = true;
}
