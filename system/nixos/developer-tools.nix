{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable {
    # Use podman by default
    virtualisation.podman = {
      enable = mkDefault (!config.virtualisation.docker.enable);
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    virtualisation.docker.enable = mkDefault false;

    # Container-to-container networking, only needed for podman since docker
    # sets these itself
    boot.kernel.sysctl = mkIf config.virtualisation.podman.enable {
      "net.ipv4.ip_forward" = mkDefault 1;
      "net.ipv6.conf.all.forwarding" = mkDefault 1;
    };

    # Allow DNS for all docker-compose networks
    networking.firewall.interfaces."podman+".allowedUDPPorts = mkIf config.virtualisation.podman.enable [53];

    environment.systemPackages = mkIf config.virtualisation.podman.enable (with pkgs; [
      podman-compose
      podman-tui
      dive
    ]);

    programs = {
      # Allow running unpatched binaries, including vscode-serer
      nix-ld.enable = mkDefault true;
    };

    # environment.systemPackages = with pkgs; [
    #   qemu_kvm
    #   OVMF
    #   libvirt
    # ];

    virtualisation.libvirtd = {
      enable = mkDefault true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = mkDefault true;
      };
    };
  };
}
