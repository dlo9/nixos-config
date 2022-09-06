{ config, pkgs, lib, inputs, ... }:

with lib;

let
  sysCfg = config.sys;
  cfg = sysCfg.networking;
  hostExports = inputs.exports.${config.networking.hostName};
  user = sysCfg.user;
  userHome = config.users.users.${user}.home;
  masterSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQy90y+nSJJfVJ4f+SKyg55lhgMTp30+UKlNXWiS3/Q david@bitwarden";
in
{
  options.sys.networking = {
    enable = mkEnableOption "networking" // { default = true; };
    wireless = mkEnableOption "wireless networking" // { default = true; };
  };

  config = mkIf cfg.enable {
    ########################
    ### Private SSH Keys ###
    ########################

    sops.secrets = {
      # Host
      "ssh-keys/host/ed25519" = {
        path = "/etc/ssh/ssh_host_ed25519_key";
        sopsFile = sysCfg.secrets.hostSecretsFile;
      };

      "ssh-keys/host/rsa" = {
        path = "/etc/ssh/ssh_host_rsa_key";
        sopsFile = sysCfg.secrets.hostSecretsFile;
      };

      # User
      "ssh-keys/${user}/ed25519" = {
        path = "${userHome}/.ssh/id_ed25519";
        owner = user;
        group = config.users.users.${user}.group;
        sopsFile = sysCfg.secrets.hostSecretsFile;
      };

      # "ssh-keys/${user}/rsa" = {
      #   path = "${userHome}/.ssh/id_rsa";
      #   owner = user;
      #   group = config.users.users.${user}.group;
      #   sopsFile = sysCfg.secrets.hostSecretsFile;
      # };

      wireless-env = mkIf cfg.wireless { };
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

    home-manager.users.${user}.home.file = {
      ".ssh/id_ed25519.pub".text = hostExports.ssh-keys.${user}.ed25519;
      # ".ssh/rsa.pub".text = hostExports.ssh-keys.${user}.rsa;
    };

    # Host
    environment.etc = {
      "/etc/ssh/ssh_host_ed25519_key.pub" = {
        text = hostExports.ssh-keys.host.ed25519;
        mode = "0644";
      };

      "/etc/ssh/ssh_host_rsa_key.pub" = {
        text = hostExports.ssh-keys.host.rsa;
        mode = "0644";
      };
    };

    ###########################
    ### Authorized SSH Keys ###
    ###########################

    # Only the master key can log in as root
    users.users.root.openssh.authorizedKeys.keys = flatten [
      inputs.mergedExports.ssh-keys.host.ed25519
      masterSshKey
    ];

    users.users.${user}.openssh.authorizedKeys.keys = flatten [
      inputs.mergedExports.ssh-keys.host.ed25519
      inputs.mergedExports.ssh-keys.${user}.ed25519
      # inputs.mergedExports.ssh-keys.${user}.rsa
      masterSshKey
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEnaSRCBwX5kziBBeMwHLoS2Pqgl2qY1EvaqT43YWPKq david@pixie"
    ];

    ################
    ### Wireless ###
    ################

    networking.wireless = mkIf cfg.wireless {
      enable = true;
      userControlled.enable = true;
      environmentFile = config.sops.secrets.wireless-env.path;
      networks = {
        BossAdams.psk = "@BOSS_ADAMS@";
        "pretty fly for a wifi".psk = "@PRETTY_FLY_FOR_A_WIFI@";
        qwertyuiop.psk = "@QWERTYUIOP@";
        LGFAK.psk = "@LGFAK@";
        "gh 42".psk = "@GH_42@";
      };
    };

    ###########
    ### VPN ###
    ###########

    services.tailscale.enable = true;

    ############
    ### Misc ###
    ############

    networking.fqdn = "${networking.hostName}";

    # Don't wait for network availability to boot
    networking.dhcpcd.wait = mkDefault "background";

    # If set to the default (true), the firewall can break some tailscale and kubernetes configs
    networking.firewall.checkReversePath = mkDefault "loose";
    networking.firewall = {
      allowPing = true;
      pingLimit = "--limit 1/second --limit-burst 10";
    };

    services.openssh.enable = true;
  };
}
