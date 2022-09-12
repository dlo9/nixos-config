{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

let
  zreplDefaults = {
    pruning = {
      keep_sender = [
        { type = "not_replicated"; }

        # Keep everything
        {
          type = "regex";
          regex = ".*";
        }
      ];

      keep_receiver = [
        # Keep everything
        {
          type = "regex";
          regex = ".*";
        }
      ];
    };
  };
in
{
  imports = [
    ./hardware.nix
  ];

  config = {
    sys = {
      gaming.enable = false;
      development.enable = false;
      graphical.enable = false;
      # TODO: kubernetes
    };

    boot.kernelParams = [ "nomodeset" ];
    boot.loader = {
      grub.mirroredBoots = [
        { devices = [ "/dev/disk/by-id/nvme-Force_MP500_17037932000122530025" ]; efiSysMountPoint = "/boot/efi0"; path = "/boot/efi0/EFI"; }
      ];
    };

    networking.interfaces.enp1s0.useDHCP = true;

    # Ethernet modules for remote boot login
    boot.initrd.kernelModules = [
      "r8169"
    ];

    # ZFS autosnapshot and replication
    services.zrepl = {
      enable = true;
      settings = {
        global = {
          logging = [
            {
              type = "stdout";
              level = "warn";
              format = "human";
              time = true;
              color = true;
            }
          ];
        };

        jobs = [
          (recursiveUpdate zreplDefaults {
            name = "drywell replication";
            type = "pull";
            root_fs = "slow/replication/drywell"; # This must exist
            interval = "1h";

            connect = {
              type = "tcp";
              address = "192.168.1.200:8888";
            };

            recv = {
              # https://zrepl.github.io/configuration/sendrecvoptions.html#placeholders
              placeholder.encryption = "inherit";
              properties.override = {
                canmount = "off";
                refreservation = "none";
              };
            };
          })
        ];
      };
    };

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
        smb = {
          path = "/slow/smb/";
          browseable = "yes";
          #content = "Network storage";
          "read only" = "no";
          #"guest ok" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "michael";
          "force group" = "users";
          "valid users" = "+samba";
          #"valid users" = "david michael";
        };
      };

      # Users must be added with `sudo smbpasswd -a <user>`
      extraConfig = let
        tailscaleNat = "100.64.0.0/10";
        in ''
          workgroup = WORKGROUP
          server string = drywell2
          netbios name = drywell2
          security = user
          #use sendfile = yes
          #max protocol = smb2
          hosts allow = 100.64. 192.168. 127.0.0.1 localhost
          hosts deny = 0.0.0.0/0
          guest account = nobody
          map to guest = bad user
        '';
    };

    # Users
    users.users.michael = {
      uid = 1001;
      isNormalUser = true;
      hashedPassword = "$6$S/H.nEE7XEPdyO6v$ENulPNgv2WGmwdCD7zluMNasQ/wPFdc61wjxC2/aFXcl9dLvbMzzeSeVI9V5dxycJaojJRFUtqKYNPJIX767P1";
      createHome = false;
      #shell = pkgs.fish;
      extraGroups = [
        "samba"
      ];
    };

    users.groups.samba = {};
    users.users.david.extraGroups = [ "samba" ];
  };
}
