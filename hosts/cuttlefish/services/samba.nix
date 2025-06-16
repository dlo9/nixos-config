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
  # Make shares visible for windows 10 clients
  services.samba-wsdd.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      5357 # wsdd
    ];

    allowedUDPPorts = [
      3702 # wsdd
    ];
  };

  services.samba = {
    enable = true;
    openFirewall = true;

    # Users must be added with `sudo smbpasswd -a <user>`
    settings = let
      tailscaleCidr = "100.64.0.0/10";
    in {
      global = {
        security = "user";
        workgroup = "WORKGROUP";
        "server string" = "samba";
        "netbios name" = "samba";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "hosts deny" = "0.0.0.0/0";
        "hosts allow" = [
          "${tailscaleCidr}"
          "192.168."
          "127.0.0.1"
          "localhost"
        ];

        # https://www.reddit.com/r/OpenMediaVault/comments/11gwi1g/significant_samba_speedperformance_improvement_by/
        "write cache size" = 2097152;
        "min receivefile size" = 16384;
        "getwd cache" = true;
      };

      chelsea = {
        path = "/home/chelsea/documents";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "chelsea";
        "force group" = "users";
        "valid users" = "+samba";
      };

      david = {
        path = "/home/david/documents";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "david";
        "force group" = "users";
        "valid users" = "+samba";
      };
    };
  };
}
