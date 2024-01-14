{
  config,
  inputs,
  lib,
  pkgs,
  hostname,
  ...
}: {
  imports = [
    ./hardware
    ./users.nix
  ];

  developer-tools.enable = true;
  graphical.enable = true;

  # SSH config
  users.users.david.openssh.authorizedKeys.keys = [
    config.hosts.bitwarden.ssh-key.pub
    config.hosts.pixie.ssh-key.pub
    config.hosts.pavil.david-ssh-key.pub
  ];

  environment.etc = {
    "/etc/ssh/ssh_host_ed25519_key.pub" = {
      text = config.hosts.${hostname}.host-ssh-key.pub;
      mode = "0644";
    };
  };

  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];
}
