{
  config,
  lib,
  inputs,
  isLinux,
  ...
}:
with lib; {
  nix = {
    registry = {
      nixpkgs-unstable.flake = mkDefault inputs.nixpkgs-unstable;
      nixpkgs-master.flake = mkDefault inputs.nixpkgs-master;
    };

    # Binary caches
    settings = {
      trusted-users = ["@wheel"];

      substituters = [
        # Default priority is 50, lower number is higher priority
        # See priority of each cache: curl https://cache.nixos.org/nix-cache-info
        "https://nix-community.cachix.org?priority=50"
        "https://cuda-maintainers.cachix.org?priority=60"
        "https://cache.flox.dev"
      ];

      trusted-substituters = [
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://cache.flox.dev"
        "https://devenv.cachix.org"
        "https://nix-serve.sigpanic.com"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-serve.sigpanic.com:fp2dLidIBUYvB1SgcAAfYIaxIvzffQzMJ5nd/jZ+hww="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      ];

      # To avoid github rate limiting
      access-tokens = "!include ${config.sops.secrets.nix-access-tokens.path}";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      accept-flake-config = true
      builders-use-substitutes = true
      keep-outputs = true
      keep-derivations = true

      connect-timeout = 5
      log-lines = 25
    '';
  };
}
