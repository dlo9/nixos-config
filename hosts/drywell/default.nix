{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:
with builtins;
with lib; {
  imports = [
    ./hardware
    ./services

    ./users.nix
  ];

  config = {
    # SSH config
    users.users.david.openssh.authorizedKeys.keys = [
      config.hosts.bitwarden.ssh-key.pub
      config.hosts.cuttlefish.david-ssh-key.pub
      config.hosts.pixie.host-ssh-key.pub
      config.hosts.pavil.david-ssh-key.pub
    ];

    environment.etc = {
      "/etc/ssh/ssh_host_ed25519_key.pub" = {
        text = config.hosts.${hostname}.host-ssh-key.pub;
        mode = "0644";
      };
    };

    # Use to enable vscode-server
    programs.nix-ld.enable = true;

    boot.kernelParams = ["nomodeset"];

    # Ethernet modules for remote boot login
    boot.initrd.kernelModules = [
      "r8169"
    ];

    fileSystems."/zfs" = {
      device = "fast/zfs";
      fsType = "zfs";
      neededForBoot = true;
    };

    boot.zfs.extraPools = ["slow"];

    boot.zfs.requestEncryptionCredentials = [
      "fast"
      "slow"
    ];
  };
}
