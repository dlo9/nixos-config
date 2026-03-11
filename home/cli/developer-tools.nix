{
  config,
  lib,
  pkgs,
  inputs,
  isLinux,
  mylib,
  ...
}:
with lib; let
  jj-sops-diff = pkgs.writeShellApplication {
    name = "jj-sops-diff";
    runtimeInputs = with pkgs; [sops delta git gnused];
    text = ''
      # jj diff formatter that decrypts ANY sops-encrypted files before diffing
      # Detects sops files by looking for ENC[AES256_GCM markers and auto-detects file type
      # Works system-wide: silently skips files that can't be decrypted (missing keys, etc.)

      LEFT="$1"
      RIGHT="$2"

      # Create writable copies for decryption
      TMPDIR=$(mktemp -d)
      trap 'rm -rf "$TMPDIR"' EXIT

      cp -rL "$LEFT" "$TMPDIR/left"
      cp -rL "$RIGHT" "$TMPDIR/right"
      chmod -R u+w "$TMPDIR"

      # Decrypt sops files in the copies
      for side in left right; do
          dir="$TMPDIR/$side"
          find "$dir" -type f 2>/dev/null | while read -r file; do
              # Check if file looks like sops-encrypted
              if grep -q "ENC\[AES256_GCM" "$file" 2>/dev/null; then
                  # Detect input type from extension
                  case "$file" in
                      *.yaml|*.yml) input_type="yaml" ;;
                      *.json) input_type="json" ;;
                      *.env) input_type="dotenv" ;;
                      *.ini) input_type="ini" ;;
                      *) input_type="binary" ;;
                  esac

                  # Attempt decryption
                  if sops decrypt --input-type "$input_type" --output-type "$input_type" "$file" > "$file.dec" 2>/dev/null; then
                      mv "$file.dec" "$file"
                  else
                      rm -f "$file.dec"
                  fi
              fi
          done
      done

      # Get terminal width - try multiple methods, default to 200
      if [[ -n "''${COLUMNS:-}" ]]; then
          width="$COLUMNS"
      elif width=$(tput cols 2>/dev/null) && [[ "$width" -gt 80 ]]; then
          : # tput worked and returned something reasonable
      else
          width=200
      fi

      # Run git diff and pipe to delta, stripping temp paths from diff headers
      git diff --no-index --no-prefix "$TMPDIR/left" "$TMPDIR/right" | \
          sed -e 's|^--- .*/left/|--- |' \
              -e 's|^+++ .*/right/|+++ |' \
              -e 's|^diff --git .*/left/\([^ ]*\) .*/right/|diff --git \1 |' | \
          delta --width "$width" || true
    '';
  };
in {
  config = mkIf config.developer-tools.enable {
    home = {
      sessionPath = [
        "$HOME/.cargo/bin"
        "$HOME/go/bin"
      ];

      packages = with pkgs;
      # All systems
        [
          yq-go
          jq
          shellcheck

          nixd # Nix language server
          nix-prefetch
          terminaltexteffects

          wrap
          fselect # Find, but with SQL
          wiper # Disk usage TUI

          tcping-go
        ]
        ++
        # On linux, use nixpkgs devenv; on darwin, use flake input to avoid boehm-gc conflicts
        (
          if isLinux
          then [
            unstable.devenv
          ]
          else let
            devenvFlake = builtins.getFlake "github:cachix/devenv/${inputs.devenv.sourceInfo.rev}";
          in [
            devenvFlake.packages.${pkgs.stdenv.hostPlatform.system}.devenv
          ]
        )
        ++ [
          dlo9.havn # Port scanner
          dlo9.cidr
          dlo9.pvw # Port viewer, pvw -aon
          carl
          dlo9.cy
          otree # JSON tree viewer
          somo

          flashrom
          #noseyparker # Credential scanner

          vulnix # Vulnerability scanner
          glow # Markdown reader
          trippy # Network diagnostics
          inxi # Hardware info

          # CSV utils
          miller
          csvlens

          fastmod # Search & replace tool
          mcat
          mosh
          jjui

          git-filter-repo
          nodejs_24 # Needed for claude code in vscode

          diff-so-fancy
          difftastic
          lnav # Log file viewer
        ]
        ++
        # Linux only
        (optionals isLinux [
          isd
          (dlo9.rustnet.override {rustPlatform = pkgs.unstable.rustPlatform;})
          claude-code
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

          revsets.bookmark-advance-to = "@-";

          signing = {
            backend = config.programs.git.settings.gpg.format;
            key = config.programs.git.settings.user.signingkey;
            behavior = "own";
          };

          ui = {
            # Decrypt sops files before diffing
            diff-formatter = ["${jj-sops-diff}/bin/jj-sops-diff" "$left" "$right"];
            #merge-editor = "mergiraf";
            diff-editor = ":builtin";
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
