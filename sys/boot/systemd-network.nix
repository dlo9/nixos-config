{ config, pkgs, lib, ... }:

# FUTURE: this doesn't work, but is in testing mode

with lib;

let
  pool-name = "pool";
in
{
  config = {
    boot.initrd.systemd = {
      enable = true;
      additionalUpstreamUnits = [
        # https://github.com/NixOS/nixpkgs/blob/5eb98948b66de29f899c7fe27ae112a47964baf8/nixos/modules/system/boot/systemd/initrd.nix#L75
        "network-online.target"
        "network-pre.target"
        "network.target"
      ];
    };

    boot.initrd.network.enable = false;

    boot.initrd.systemd.storePaths = [
      "${pkgs.openssh}/bin/sshd"
      "${pkgs.glibc}/lib/libnss_files.so.2"
    ];

    boot.initrd.systemd.services.sshd-init =
      let
        sshdCfg = config.services.openssh;

        sshdConfig = ''
          Port 22

          PasswordAuthentication no
          ChallengeResponseAuthentication no

          HostKey /var/ssh_host_rsa_key

          KexAlgorithms ${concatStringsSep "," sshdCfg.kexAlgorithms}
          Ciphers ${concatStringsSep "," sshdCfg.ciphers}
          MACs ${concatStringsSep "," sshdCfg.macs}

          LogLevel ${sshdCfg.logLevel}

          ${if sshdCfg.useDns then ''
            UseDNS yes
          '' else ''
            UseDNS no
          ''}
        '';

        authorizedKeys = config.users.users.${config.sys.user}.openssh.authorizedKeys.keys;
        shell = "/bin/ash";
      in
      {
        conflicts = [
          "multi-user.target"
          # "sshd.service"
        ];

        # systemd-networkd-wait-online.service
        #requires = [ "network-online.target" ];
        #after = [ "network-online.target" ];
        requires = [ "systemd-networkd.service" "systemd-networkd-wait-online.service" ];
        after = [ "systemd-networkd.service" "systemd-networkd-wait-online.service" ];

        wantedBy = [
          # Name comes from initrd creation: https://github.com/NixOS/nixpkgs/blob/5eb98948b66de29f899c7fe27ae112a47964baf8/nixos/modules/tasks/filesystems/zfs.nix#L106
          "zfs-import-${pool-name}.service"
        ];

        unitConfig = {
          DefaultDependencies = "no";
        };

        before = [ "zfs-import-${pool-name}.service" ];

        preStart = ''
          echo '${shell}' > /etc/shells
          echo 'root:x:0:0:root:/root:${shell}' > /etc/passwd
          echo 'sshd:x:1:1:sshd:/var/empty:/bin/nologin' >> /etc/passwd
          echo 'passwd: files' > /etc/nsswitch.conf

          mkdir -p /var/log /var/empty
          touch /var/log/lastlog

          mkdir -p /etc/ssh
          echo -n ${lib.escapeShellArg sshdConfig} > /etc/ssh/sshd_config

          echo "export PATH=$PATH" >> /etc/profile
          echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /etc/profile

          mkdir -p /root/.ssh
          ${concatStrings (map (key: ''
            echo ${escapeShellArg key} >> /root/.ssh/authorized_keys
          '') authorizedKeys)}

          # keys from Nix store are world-readable, which sshd doesn't like
          chmod 0600 "/var/ssh_host_rsa_key"
        '';

        script = ''
          ${pkgs.openssh}/bin/sshd -e
        '';
      };

    # TODO: abstract
    # https://github.com/NixOS/nixpkgs/blob/5eb98948b66de29f899c7fe27ae112a47964baf8/nixos/modules/system/boot/initrd-ssh.nix#L209
    boot.initrd.secrets = {
      "/var/ssh_host_rsa_key" = "/var/ssh_host_rsa_key";
    };
  };
}
