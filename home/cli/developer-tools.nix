{
  config,
  lib,
  pkgs,
  isLinux,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable (with pkgs.dlo9.lib; {
    home = {
      sessionPath = [
        "$HOME/.cargo/bin"
      ];

      packages = with pkgs;
      # All systems
        [
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

          dlo9.havn # Port scanner
          dlo9.cidr
          dlo9.pvw # Port viewer, pvw -aon
          dlo9.carl
          dlo9.cy
          dlo9.posting # Postman-like clint
          # dlo9.otree # JSON tree viewer
          # dlo9.rainfrog # Postgres TUI
        ]
        ++
        # Linux only
        (optionals isLinux [
          distrobox
        ]);
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
