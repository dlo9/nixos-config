{
  config,
  lib,
  ...
}: let
  isSigpanicNixServe = config.services.nix-serve.enable or false;
in {
  nix = {
    # Binary caches
    settings = {
      trusted-users = ["@wheel"];

      substituters =
        [
          # Default priority is 50, lower number is higher priority
          # See priority of each cache: curl https://cache.nixos.org/nix-cache-info
          "https://nix-community.cachix.org?priority=50"
          "https://cuda-maintainers.cachix.org?priority=60"
        ]
        ++ lib.optional (!isSigpanicNixServe) "https://nix-serve.sigpanic.com?priority=100";

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-serve.sigpanic.com:fp2dLidIBUYvB1SgcAAfYIaxIvzffQzMJ5nd/jZ+hww="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
