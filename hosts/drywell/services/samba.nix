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

      sue = {
        path = "/slow/documents/sue";
        browseable = "yes";
        "read only" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "sue";
        "force group" = "users";
        "valid users" = "+samba";
      };
    };
  };
}
