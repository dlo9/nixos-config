{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable {
    home = {
      sessionPath = [
        "$HOME/.cargo/bin"
      ];

      packages = with pkgs; [
        # Rust
        rustup

        yq-go
        jq
        shellcheck

        nixd # Nix language server
        nix-prefetch
        pkgs.unstable.terminaltexteffects

        gh-dash
      ];
    };

    # https://github.com/dlvhdr/gh-dash
    xdg.configFile."gh-dash/config.yml".text = builtins.toJSON {
      prSections = [
        {
          title = "My Pull Requests";
          filters = "is:open author:@me";
          layout.author.hidden = true;
        }
        {
          title = "Needs My Review";
          filters = "is:open review-requested:@me -team-review-requested:apex-fintech-solutions/engineering";
        }
        {
          title = "Involved";
          filters = "is:open involves:@me - author:@me";
        }
      ];
    };
  };
}
