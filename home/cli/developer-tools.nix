{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable (with pkgs.dlo9.lib; {
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
        devenv
        gitu # Git TUI
        # dlo9.pocker # Docker TUI - too many python deps
        dlo9.toolong
        tcping-go
        distrobox
      ];
    };

    programs = {
      zellij.enable = true;
    };

    xdg.configFile = xdgFiles {
      # https://github.com/dlvhdr/gh-dash
      "gh-dash/config.yml" = {
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
  });
}
