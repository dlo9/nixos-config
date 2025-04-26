{
  config,
  lib,
  pkgs,
  isLinux,
  mylib,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable {
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
          unstable.devenv
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

          flashrom
          #noseyparker # Credential scanner
          glances # Monitoring utility

          vulnix # Vulnerability scanner
          glow # Markdown reader
          trippy # Network diagnostics
          inxi # Hardware info

          # CSV utils
          miller
          csvlens

          lua
        ]
        ++
        # Linux only
        (optionals isLinux [
          isd
        ]);
    };

    programs = {
      zellij.enable = true;

      helix = {
        enable = true;
        settings = {
          theme = "kanagawa";
        };
      };

      yazi = {
        settings = {
          manager = {
            sort_by = "natural";
            sort_sensitive = false;
            sort_reverse = false;
            sort_dir_first = true;
            linemode = "size";
            show_hidden = true;
            show_symlink = true;
          };
        };
      };
    };

    xdg.configFile = mylib.xdgFiles {
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
  };
}
