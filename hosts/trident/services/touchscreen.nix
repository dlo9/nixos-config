{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  services.cage = {
    enable = true;
    program = "${pkgs.klipperscreen}/bin/KlipperScreen";
    user = "pi";

    environment = {
      WLR_LIBINPUT_NO_DEVICES = "1";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
  };

  # Rotate the screen after cage starts
  systemd.services."cage-tty1" = let
    # Cage has a race condition and fails to start a user session without this
    requirements = ["user.slice" "user@1000.service" "systemd-user-sessions.service" "dbus.socket"];
  in rec {
    requires = requirements;
    after = requirements;

    serviceConfig = {
      TimeoutStartSec = "30s";
      Restart = "always";
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
}
