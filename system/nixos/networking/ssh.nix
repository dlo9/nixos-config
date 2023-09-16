{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  hostExports = inputs.exports.${config.networking.hostName};
  user = config.sys.user;
  userHome = config.users.users.${user}.home;
  masterSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQy90y+nSJJfVJ4f+SKyg55lhgMTp30+UKlNXWiS3/Q david@bitwarden";
  hostExports = config.hosts.${config.networking.hostName};
in {
  imports = [
    ./systemd.nix
    ./vpn.nix
  ];

  config = {
    sops.secrets = {
      wireless-env = mkIf cfg.wireless {};
    };

    # Necessary for distributed builds
    programs.ssh.extraConfig = ''
      Match user root host cuttlefish
          IdentitiesOnly yes
          IdentityFile /etc/ssh/ssh_host_ed25519_key
    '';

    #######################
    ### Public SSH Keys ###
    #######################

    # home-manager.users.${user}.home.file = {
    #   ".ssh/id_ed25519.pub".text = hostExports.ssh-keys.${user}.ed25519;
    # };

    # Host
    # environment.etc = {
    #   "/etc/ssh/ssh_host_ed25519_key.pub" = {
    #     text = hostExports.ssh-keys.host.ed25519;
    #     mode = "0644";
    #   };

    #   "/etc/ssh/ssh_host_rsa_key.pub" = {
    #     text = hostExports.ssh-keys.host.rsa;
    #     mode = "0644";
    #   };
    # };

    ###########################
    ### Authorized SSH Keys ###
    ###########################

    users.users.${user}.openssh.authorizedKeys.keys = flatten [
      # inputs.mergedExports.ssh-keys.${user}.ed25519
      masterSshKey
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEnaSRCBwX5kziBBeMwHLoS2Pqgl2qY1EvaqT43YWPKq david@pixie"
    ];

    # Enable the ssh agent
    programs.ssh.startAgent = mkDefault true;
    security.pam.enableSSHAgentAuth = mkDefault true;

    services.openssh = {
      enable = mkDefault true;
      settings.PermitRootLogin = "no";
    };

    programs.mosh = {
      enable = mkDefault true;
      withUtempter = mkDefault false;
    };
  };
}
