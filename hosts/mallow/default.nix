{
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  security.pki.certificateFiles = [
    ./ca-certificates.crt
  ];

  home-manager.users.dorchard = {
    xdg.configFile."wrap.yaml" = {
      text = mkForce null;
      source = ./wrap.yaml;
    };

    home.packages = with pkgs; [
      kubectl

      # gcloud components install gke-gcloud-auth-plugin
      (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
        gke-gcloud-auth-plugin
      ]))

      rnix-lsp # Nix language server

      # Use a new launcher since spotlight doesn't find nix GUI applications:
      # https://github.com/nix-community/home-manager/issues/1341
      raycast

      # Fonts
      # Nerdfonts is huge, so only install specific fonts
      # https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/data/fonts/nerdfonts/shas.nix
      (nerdfonts.override {
        fonts = [
          "Noto"
        ];
      })

      noto-fonts-emoji
    ];

    programs.ssh = {
      enable = true;
      matchBlocks."d1lrtcappprd?".extraOptions = {
        HostKeyAlgorithms = "+ssh-rsa";
        PubkeyAcceptedAlgorithms = "+ssh-rsa";
      };
    };
  };
}
