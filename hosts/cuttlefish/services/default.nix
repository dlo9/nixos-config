{ ... }:

{
  imports = [
    # ./authentik.nix
    # ./authorization.nix
    ./certs.nix
    ./checkmk.nix
    ./ddns.nix
    ./jellyfin.nix
    ./netdata.nix
    ./caddy.nix
    # ./zabbix.nix
    #./nginx.nix
  ];

  config = {
    # users.groups.nix-container1.gid = 71;
    # users.users.nix-container1 = {
    #   isSystemUser = true;
    #   uid = 71;
    #   group = "nix-container1";
    # };

    # Zabbix
    # users.groups.zabbix.gid = 180;
    # users.users.zabbix.uid = 180;
  };
}
