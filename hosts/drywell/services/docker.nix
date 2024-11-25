{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    dive
    podman-tui
    podman-compose
  ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Allow DNS for all docker-compose networks
  networking.firewall.interfaces."podman+".allowedUDPPorts = [53];
}
