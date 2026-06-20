{
  config,
  pkgs,
  lib,
  ...
}:
# Resources:
# - [systemd example](https://gist.github.com/maddes-b/e487d1f95f73f5d40805315f0232d5d9)
# - [Bridge vs Macvlan](https://hicu.be/bridge-vs-macvlan)
with lib; let
  MACs = {
    # Gets 32:1e:1c:d7:56:1a on boot somehow??
    cuttlefish = "d8:bb:c1:c8:5c:da";
  };
in {
  config = {
    # Enable IP forwarding for tailscale, kubernetes, and VMs
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkForce 1;
      "net.ipv6.conf.all.forwarding" = lib.mkForce 1;
    };

    # Re-assert accept_ra=2 after networkd configures enp39s0: networkd zeroes accept_ra
    # on every managed link, and its IPv6AcceptRA= boolean can't express the value 2.
    # Removable once systemd honors IPv6AcceptRA=true under global forwarding:
    # https://github.com/systemd/systemd/issues/40322
    systemd.services.enp39s0-accept-ra = {
      description = "Accept IPv6 Router Advertisements on enp39s0 despite IPv6 forwarding";
      after = ["systemd-networkd.service"];
      wants = ["systemd-networkd.service"];
      wantedBy = ["multi-user.target"];
      # Re-run if networkd is restarted (which would reset accept_ra back to 0).
      partOf = ["systemd-networkd.service"];
      path = [pkgs.coreutils];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "enp39s0-accept-ra" ''
          ra=/proc/sys/net/ipv6/conf/enp39s0
          # Wait for networkd to bring the link up (it configures asynchronously).
          for _ in $(seq 1 30); do
            [ "$(cat /sys/class/net/enp39s0/operstate 2>/dev/null)" = up ] && break
            sleep 1
          done

          # Re-assert a few times to win the race with networkd's link config.
          for _ in 1 2 3; do echo 2 > "$ra/accept_ra" 2>/dev/null; sleep 2; done

          # Toggle IPv6 to solicit an RA now instead of waiting for the next periodic one.
          echo 1 > "$ra/disable_ipv6" 2>/dev/null
          echo 0 > "$ra/disable_ipv6" 2>/dev/null
        '';
      };
    };
  };
}
