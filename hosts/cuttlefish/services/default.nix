{...}: {
  imports = [
    ./caddy.nix
    ./certs.nix
    ./ddns.nix
    ./jellyfin.nix
    ./kubernetes.nix
    ./netdata.nix
    ./nfs.nix
    ./zrepl.nix
  ];

  config = {
    # users.groups.nix-container1.gid = 71;
    # users.users.nix-container1 = {
    #   isSystemUser = true;
    #   uid = 71;
    #   group = "nix-container1";
    # };

    # Networking
    networking.nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = "cuttlefish";
    };
  };
}
