{
  config,
  inputs,
  pkgs,
  lib,
  hostname,
  ...
}:
with lib; {
  imports = [
    ./hardware
    ./network.nix
    ./initrd-wifi.nix
  ];

  config = {
    users.users.david.openssh.authorizedKeys.keys = [
      config.hosts.bitwarden.ssh-key.pub
      config.hosts.pavil.david-ssh-key.pub
    ];

    environment.etc = {
      "/etc/ssh/ssh_host_ed25519_key.pub" = {
        text = config.hosts.${hostname}.host-ssh-key.pub;
        mode = "0644";
      };
    };

    # Bluetooth
    hardware.bluetooth.enable = true;

    # Could also override systemd's DefaultTimeoutStopSec, but other services seem to behave
    systemd.extraConfig = "DefaultTimeoutStopSec=10s";

    nix.distributedBuilds = true;

    networking.firewall.allowedTCPPorts = [
      # Authentik: Is this necessary?
      9000
    ];
  };
}
