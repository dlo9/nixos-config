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
    samba = mkEnableOption "samba mounts" // { default = false; };
    authenticateTailscale = mkEnableOption "authenticate tailscale" // { default = false; };
  };

  config = mkMerge [
    (mkIf cfg.enable {
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

      sops.secrets.tailscale-auth-key = mkIf cfg.authenticateTailscale {
        sopsFile = sysCfg.secrets.hostSecretsFile;
      };

      systemd.services.tailscale-anthenticate = mkIf cfg.authenticateTailscale {
        script = ''
          tailscale up --auth-key "file:${config.sops.secrets.tailscale-auth-key.path}"
        '';
        wantedBy = [ "multi-user.target" ];
      };


      #####################
      ### Remote access ###
      #####################

      services.openssh.enable = true;
      programs.mosh.enable = true;
      programs.mosh.withUtempter = false;

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
    })
    ({
      #############
      ### Samba ###
      #############

      # For mount.cifs, required unless domain name resolution is not needed.
      environment.systemPackages = with pkgs; [ cifs-utils gnome.seahorse ];
      services.gnome.gnome-keyring.enable = true; # TODO: unlock password doesn't work
      sops.secrets.cuttlefish-samba-secrets = { };

      # TODO: opt-in better
      fileSystems = mkIf (config.networking.hostName != "drywell" && config.networking.hostName != "cuttlefish") (
        let
          host = "cuttlefish";
          # this line prevents hanging on network split
          automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
          cuttlefish-share = name: {
            # Would prefer to use the following, but then /run/users/UID is created with the wrong (root) permission
            #"/run/user/${toString config.users.users."${sysCfg.user}".uid}/${name}"
            "/cuttlefish/${name}" = {
              device = "//${host}/${name}";
              fsType = "cifs";
              options = [ "${automount_opts},credentials=${config.sops.secrets.cuttlefish-samba-secrets.path},uid=${toString config.users.users."${sysCfg.user}".uid},gid=${toString config.users.groups.users.gid}" ];
            };
          };
        in
        foldl' (x: y: x // y) { } [
          (cuttlefish-share "documents")
          (cuttlefish-share "media")
        ]);
    })
  ];
}
