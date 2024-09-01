{
  config,
  lib,
  inputs,
  ...
}: let
  isSigpanicNixServe = config.services.nix-serve.enable or false;
in {
  nix = {
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
      nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
      nixpkgs-master.flake = inputs.nixpkgs-master;
    };

    # Binary caches
    settings = {
      trusted-users = ["@wheel"];

      substituters =
        [
          # Default priority is 50, lower number is higher priority
          # See priority of each cache: curl https://cache.nixos.org/nix-cache-info
          "https://nix-community.cachix.org?priority=50"
          "https://cuda-maintainers.cachix.org?priority=60"
          "https://cache.flox.dev"
        ]
        ++ lib.optional (!isSigpanicNixServe) "https://nix-serve.sigpanic.com?priority=100";

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-serve.sigpanic.com:fp2dLidIBUYvB1SgcAAfYIaxIvzffQzMJ5nd/jZ+hww="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      ];
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
      keep-outputs = true
      keep-derivations = true

      connect-timeout = 5
      log-lines = 25
    '';
  };
}
