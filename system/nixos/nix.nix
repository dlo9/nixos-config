{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  enableSigpanicSubstituter = !(config.services.nix-serve.enable or false);
in {
  # Autoupgrade
  # Can be run manually with: `systemctl start nixos-upgrade.service`
  system.autoUpgrade = {
    enable = mkDefault false;
    allowReboot = mkDefault false;
    flake = "path:///etc/nixos#${config.networking.hostName}";
    flags = ["--recreate-lock-file" "--commit-lock-file"];
    dates = "Sat, 02:00";
  };

  nix = {
    gc = {
      automatic = true;
      dates = "Sat, 01:00";
      options = "--delete-older-than 14d";
    };

    optimise = {
      automatic = true;
      dates = ["Sat, 03:00"];
    };

    # Use cuttlefish as a remote builder
    buildMachines = [
      {
        hostName = "nix-serve.sigpanic.com";
        sshUser = "nix-remote";
        sshKey = config.sops.secrets.host-ssh-key.path;
        publicHostKey = builtins.readFile (pkgs.runCommandLocal "base64-key" {} ''
          printf "%s" '${config.hosts.cuttlefish.host-ssh-key.pub}' | ${pkgs.coreutils-full}/bin/base64 -w0 > $out
        '');
        protocol = "ssh-ng";
        systems = ["x86_64-linux" "aarch64-linux"];

        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];

    settings.substituters = lib.optional enableSigpanicSubstituter "https://nix-serve.sigpanic.com?priority=100";
  };
}
