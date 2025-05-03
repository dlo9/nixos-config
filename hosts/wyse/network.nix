{lib, ...}: {
  # Enable IP forwarding for tailscale, kubernetes, and VMs
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = lib.mkForce 1;
    "net.ipv6.conf.all.forwarding" = lib.mkForce 1;
  };
}
