{...}: {
  imports = [
    ./certs.nix
    ./ddns.nix
    ./jellyfin.nix
    ./netdata.nix
    ./caddy.nix
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
