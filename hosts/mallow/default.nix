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
