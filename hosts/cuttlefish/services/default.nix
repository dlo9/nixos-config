{ ... }:

{
  imports = [
    ./authentik.nix
    ./authorization.nix
    ./certs.nix
    ./ddns.nix
    ./jellyfin.nix
    ./caddy.nix
    #./nginx.nix
  ];

  config = {
    users.groups.nix-container1.gid = 71;
    users.users.nix-container1 = {
      isSystemUser = true;
      uid = 71;
      group = "nix-container1";
    };
  };
}
