{ config, pkgs, lib, inputs, ... }:

with builtins;
with lib;

{
  config = {
    # Samba
    services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

    networking.firewall.allowedTCPPorts = [
      5357 # wsdd
    ];

    networking.firewall.allowedUDPPorts = [
      3702 # wsdd
    ];

    services.samba =
      let
        defaults = {
          browseable = "yes";
          "read only" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force group" = "users";
        };
      in
      {
        enable = true;
        openFirewall = true;

        shares = {
          chelsea = defaults // {
            path = "/slow/smb/chelsea";
            "force user" = "chelsea";
            "valid users" = "+samba";
          };

          chelsea-backup = defaults // {
            path = "/slow/smb/chelsea-backup";
            "force user" = "chelsea";
            "valid users" = "+samba";
          };

          documents = defaults // {
            path = "/slow/documents";
            "force user" = "david";
            "valid users" = "david";
          };

          media = defaults // {
            path = "/slow/media";
            "force user" = "david";
            "valid users" = "david";
          };
        };

        # Users must be added with `sudo smbpasswd -a <user>`
        extraConfig =
          let
            tailscaleNat = "100.64.0.0/10";
          in
          ''
            workgroup = WORKGROUP
            server string = cuttlefish
            netbios name = cuttlefish
            security = user
            #use sendfile = yes
            #max protocol = smb2
            hosts allow = 100.64.0.0/10 192.168. 127.0.0.1 localhost
            hosts deny = 0.0.0.0/0
            guest account = nobody
            map to guest = bad user
          '';
      };

    # Users
    users.users.chelsea = {
      uid = 1001;
      group = "users";
      isSystemUser = true;
      createHome = false;
      extraGroups = [
        "samba"
      ];
    };

    users.groups.samba = { };
    users.users.david.extraGroups = [ "samba" ];
  };
}
