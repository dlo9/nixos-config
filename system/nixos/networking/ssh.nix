{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  masterSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQy90y+nSJJfVJ4f+SKyg55lhgMTp30+UKlNXWiS3/Q david@bitwarden";
  hosts = config.hosts.${config.networking.hostName};
in {
  imports = [
    ./systemd.nix
    ./vpn.nix
  ];

  config = {
    ###########################
    ### Authorized SSH Keys ###
    ###########################

    # TODO: for each admin user
    # users.users.${user}.openssh.authorizedKeys.keys = flatten [
    #   masterSshKey
    #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEnaSRCBwX5kziBBeMwHLoS2Pqgl2qY1EvaqT43YWPKq david@pixie"
    # ];

    # Enable the ssh agent
    programs.ssh.startAgent = mkDefault true;
    security.pam.sshAgentAuth.enable = mkDefault true;

    services.openssh = {
      enable = mkDefault true;
      settings.PermitRootLogin = "no";

      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    programs.mosh = {
      enable = mkDefault true;
      withUtempter = mkDefault false;
    };
  };
}
