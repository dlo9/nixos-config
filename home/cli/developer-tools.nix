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
          yq-go
          jq
          shellcheck

          nixd # Nix language server
          nix-prefetch
          unstable.terminaltexteffects

          wrap
          fselect # Find, but with SQL
          wiper # Disk usage TUI
          serpl # CLI find & replace: scooter is another option

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
          dlo9.somo

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
          (dlo9.rustnet.override { rustPlatform = pkgs.unstable.rustPlatform; })
        ]);
    };

    programs = {
      zellij.enable = true;

      helix = {
        enable = true;
        settings = {
          theme = "bogster";
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

      jujutsu = {
        enable = true;
        package = pkgs.unstable.jujutsu;
        settings = {
          user = {
            name = config.programs.git.userName;
            email = config.programs.git.userEmail;
          };

          git = {
            auto-local-bookmark = true;
            private-commits = "description(glob:'wip:*') | description(glob:'private:*')";
          };

          aliases = {
            tug = ["bookmark" "move" "--from" "heads(::@- & bookmarks())" "--to" "@-"];
            abandon-empty = ["abandon" "-r" "(empty() & description(exact:'')) ~ root()"];
          };

          revset-aliases = {
            "summary()" = "@ | ancestors(remote_bookmarks().., 2) | trunk()";
          };

          signing = {
            backend = config.programs.git.extraConfig.gpg.format;
            key = config.programs.git.extraConfig.user.signingkey;
            behavior = "own";
          };

          ui = {
            # delta, diff-so-fancy, and difftastic are other alternatives
            # diffnav is great, but only works with diff: https://github.com/dlvhdr/diffnav/issues/28
            pager = "${pkgs.delta}/bin/delta";
            diff-formatter = ":git"; # Required by pager
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
