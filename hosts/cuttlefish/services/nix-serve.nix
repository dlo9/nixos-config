{
  config,
  pkgs,
  ...
}: {
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  services.nix-serve = {
    enable = true;
    port = 5000;
    openFirewall = true;
    secretKeyFile = config.sops.secrets.nix-serve-private-key.path;
  };

  users.users.nix-remote = {
    group = "nix-remote";

    isSystemUser = true;
    hashedPassword = "!";
    shell = pkgs.dash;

    openssh.authorizedKeys.keys = [
      config.hosts.pixie.host-ssh-key.pub
      config.hosts.pavil.host-ssh-key.pub
    ];
  };

  users.groups.nix-remote = {};

  nix.settings.trusted-users = ["nix-remote"];
}
