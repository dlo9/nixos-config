{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  imports = [
    ./ssh.nix
    ./systemd.nix
    ./vpn.nix
    ./wireless.nix
  ];

  networking.fqdn = "${networking.hostName}";

  # If set to the default (true), the firewall can break some tailscale and kubernetes configs
  networking.firewall.checkReversePath = mkDefault "loose";
  networking.firewall = {
    allowPing = true;
    pingLimit = "--limit 1/second --limit-burst 10";
  };

  services.davfs2.enable = true;
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
}
