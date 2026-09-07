{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  home-manager.users.david.programs.git.settings.safe.directory = config.services.gitwatch.klipper.path;

  # gitwatch pushes as `pi`, whose known_hosts has no entry for the Forgejo SSH
  # ingress. Note this is a different host key than git.sigpanic.com:22.
  programs.ssh.knownHosts."[git.sigpanic.com]:2222".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhHlkiTHEExGsOZwPVXq0qos3oQAx+0Z9QHJmMwzO0J";

  services.gitwatch = {
    klipper = {
      enable = true;
      user = config.home-manager.users.david.home.username;
      remote = "ssh://git@git.sigpanic.com:2222/david/trident.git";
      path = config.services.klipper.configDir;
    };
  };
}
