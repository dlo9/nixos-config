{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable {
    programs = {
      # IDE
      vscode = {
        enable = true;
        package = pkgs.vscode-fhs;

        # Don't enable these settings, or all settings must be managed by nix
        # enableUpdateCheck = false;
        # enableExtensionUpdateCheck = false;

        # Allow extension installations/updates
        mutableExtensionsDir = true;

        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide

          # Enables SSH into a Nix remote host:
          # https://nixos.wiki/wiki/Visual_Studio_Code#Nix-sourced_VS_Code_to_NixOS_host
          ms-vscode-remote.remote-ssh
        ];
      };
    };
  };
}
