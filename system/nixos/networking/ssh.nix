{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  imports = [
    ./systemd.nix
    ./vpn.nix
  ];

  config = {
    ###########################
    ### Authorized SSH Keys ###
    ###########################

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
