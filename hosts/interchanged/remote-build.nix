{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Enable SSH
  services.openssh = {
    enable = true;

    extraConfig = ''
      PermitRootLogin no
      AllowUsers nix-remote
    '';
  };

  system.activationScripts.extraActivation.text = ''
    # Grant SSH access to nix-remote user
    dseditgroup -o edit -a nix-remote -t user com.apple.access_ssh 2>/dev/null || {
      dseditgroup -o create com.apple.access_ssh
      dseditgroup -o edit -a nix-remote -t user com.apple.access_ssh
    }

    # Copy keys to the linux-builder
    mkdir -p /var/lib/linux-builder/keys
    cp -f /etc/ssh/ssh_host_ed25519_key /var/lib/linux-builder/keys/builder_ed25519
    cp -f /etc/ssh/ssh_host_ed25519_key.pub /var/lib/linux-builder/keys/builder_ed25519.pub
  '';

  nix.linux-builder = {
    enable = true;

    config = {
      virtualisation.cores = 4;

      # Hint: need to comment this out when building for the first time
      users.users.builder.openssh.authorizedKeys.keys = config.users.users.nix-remote.openssh.authorizedKeys.keys;

      nixpkgs = {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
      };

      # Disable RSA host key
      #services.openssh.hostKeys = [
      #  {
      #    path = "/etc/ssh/ssh_host_ed25519_key";
      #    type = "ed25519";
      #  }
      #];
    };

    systems = ["aarch64-linux"];
  };

  # Create nix-remote user
  users.knownUsers = [config.users.users.nix-remote.name];
  users.users.nix-remote = {
    uid = 404;
    gid = config.users.groups.nix-remote.gid;

    shell = pkgs.dash;

    openssh.authorizedKeys.keys = [
      config.hosts.cuttlefish.host-ssh-key.pub
    ];
  };

  # Create nix-remote group, and allow it to use nix
  users.knownGroups = [config.users.groups.nix-remote.name];
  users.groups.nix-remote.gid = 404;

  nix.settings.trusted-users = [config.users.groups.nix-remote.name];
}
