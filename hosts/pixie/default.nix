{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:
with lib; {
  config = {
    system.stateVersion = "23.11";

    # Users
    home-manager.config = ./home.nix;

    user.shell = "${config.home-manager.config.programs.fish.package}/bin/fish";

    # TODO: Remove when distributedBuilds option is introduced
    environment.etc."nix/machines" = ''
      ssh-ng://nix-remote@cuttlefish x86_64-linux,aarch64-linux /etc/ssh/ssh_host_ed25519_key 4 2 nixos-test,benchmark,big-parallel,kvm - c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUtENkFxN3hNM3pleFBYY2s1Zk9mODF4VnpIUHZSdVQrZzJwRytQVUg0b3cgcm9vdEBjdXR0bGVmaXNo
    '';

    nix = {
      substituters = [
        # Default priority is 50, lower number is higher priority
        # See priority of each cache: curl https://cache.nixos.org/nix-cache-info
        "https://nix-community.cachix.org?priority=50"
        "https://cuda-maintainers.cachix.org?priority=60"
        "https://cache.flox.dev"
        "https://nix-serve.sigpanic.com?priority=100"
      ];

      trustedPublicKeys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-serve.sigpanic.com:fp2dLidIBUYvB1SgcAAfYIaxIvzffQzMJ5nd/jZ+hww="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      ];

      extraOptions = ''
        experimental-features = nix-command flakes
        builders-use-substitutes = true
        keep-outputs = true
        keep-derivations = true

        connect-timeout = 5
        log-lines = 25
      '';
    };

    # Tailscale hosts
    networking.hosts = {
      "100.111.108.84" = ["pavil"];
      "100.97.145.42" = ["cuttlefish"];
      "100.78.52.90" = ["drywell"];
      "100.115.65.29" = ["kvm-cuttlefish"];
      "100.75.234.109" = ["kvm-drywell"];
      "100.124.233.7" = ["opnsense"];
    };

    environment.packages = with pkgs; [
    ];
  };
}
