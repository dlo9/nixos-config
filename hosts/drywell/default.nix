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

    # Samba
    services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

    networking.firewall.allowedTCPPorts = [
      5357 # wsdd
    ];

    networking.firewall.allowedUDPPorts = [
      3702 # wsdd
    ];

    services.samba = {
      enable = true;
      openFirewall = true;

      shares = {
        michael = {
          path = "/slow/documents/michael";
          browseable = "yes";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "michael";
          "force group" = "users";
          "valid users" = "+samba";
        };
      };

      # Users must be added with `sudo smbpasswd -a <user>`
      settings = let
        tailscaleCidr = "100.64.0.0/10";
      in {
        global = {
          security = "user";
          workgroup = "WORKGROUP";
          "server string" = "drywell";
          "netbios name" = "drywell";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          "hosts deny" = "0.0.0.0/0";
          "hosts allow" = [
            "${tailscaleCidr}"
            "192.168."
            "127.0.0.1"
            "localhost"
          ];
        };
      };
    };
  };
}
