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
    boot.loader = {
      grub.mirroredBoots = [
        {
          devices = ["/dev/disk/by-id/nvme-Force_MP500_17037932000122530025"];
          efiSysMountPoint = "/boot/efi0";
          path = "/boot/efi0/EFI";
        }
        #{ devices = [ "/dev/disk/by-id/usb-Leef_Supra_0171000000030148-0:0" ]; efiSysMountPoint = "/boot/efi1"; path = "/boot/efi1/EFI"; }
      ];
    };

    # Ethernet modules for remote boot login
    boot.initrd.kernelModules = [
      "r8169"
    ];

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
      extraConfig = let
        tailscaleCidr = "100.64.0.0/10";
      in ''
        workgroup = WORKGROUP
        server string = drywell
        netbios name = drywell
        security = user
        #use sendfile = yes
        #max protocol = smb2
        hosts allow = ${tailscaleCidr} 192.168. 127.0.0.1 localhost
        hosts deny = 0.0.0.0/0
        guest account = nobody
        map to guest = bad user
      '';
    };

    virtualisation.docker = {
      enable = mkDefault true;
      enableOnBoot = mkDefault true;
    };
  };
}
