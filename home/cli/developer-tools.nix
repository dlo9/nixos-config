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
          toolong
          tcping-go

          dlo9.havn # Port scanner
          dlo9.cidr
          dlo9.pvw # Port viewer, pvw -aon
          carl
          dlo9.cy
          posting # Postman-like clint
          otree # JSON tree viewer
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
          fastmod # Search & replace tool
          parallel
          unstable.mcat
          mosh
          jjui

          git-filter-repo
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
      mergiraf.enable = true;

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
          user = config.programs.git.settings.user;

          remotes.origin.auto-track-bookmarks = "glob:*";

          git = {
            private-commits = "description(glob:'private:*') | bookmarks(glob:'private-*')";
          };

          aliases = {
            # Move the closest bookmark to the previous commit
            tug = ["bookmark" "move" "--from" "heads(::@- & bookmarks())" "--to" "@-"];

            # Abandon descriptionless, empty commits
            abandon-empty = ["abandon" "-r" "(empty() & description(exact:'')) ~ root()"];

            # Create a new commit at the beginning of this branch
            prepend = ["new" "-B" "roots(trunk()..@)"];

            # Fetch and rebase
            update = ["util" "exec" "--" "sh" "-c" "jj git fetch && jj rebase -b @ -d 'trunk()'"];

            # Log all
            ll = ["log" "-r" "all()"];
          };

          revset-aliases = {
            "summary()" = "@ | ancestors(remote_bookmarks().., 2) | trunk()";

            # Commits which aren't part of a bookmark
            "dangling()" = "~::bookmarks()";

            # Commits which only exist locally (ignoring empty heads)
            "local_only()" = "~::remote_bookmarks() ~(heads(all()) & empty())";

            # Commits which were likely left behind test changes:
            #   - not the current change
            #   - not on a remote
            #   - no description
            #   - no child commits with descriptions
            "temp()" = "description(exact:'') ~::(~description(exact:'')) ~::remote_bookmarks() ~@";
          };

          signing = {
            backend = config.programs.git.settings.gpg.format;
            key = config.programs.git.settings.user.signingkey;
            behavior = "own";
          };

          ui = {
            # delta, diff-so-fancy, and difftastic are other alternatives
            # diffnav is great, but only works with diff: https://github.com/dlvhdr/diffnav/issues/28
            pager = "${pkgs.delta}/bin/delta";
            diff-formatter = ":git"; # Required by pager
            #merge-editor = "mergiraf";
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
