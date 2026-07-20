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
    runtimeInputs = with pkgs; [sops difftastic];
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

      # Detect terminal width from /dev/tty since stdout is piped to jj's pager
      width=""

      if [[ -r /dev/tty ]]; then
          width=$(stty size </dev/tty 2>/dev/null | awk '{print $2}')
      fi

      if ! [[ "$width" =~ ^[1-9][0-9]*$ ]] && [[ -n "''${COLUMNS:-}" ]]; then
          width="$COLUMNS"
      fi

      if ! [[ "$width" =~ ^[1-9][0-9]*$ ]]; then
          width=200
      fi

      difft --color always --display side-by-side-show-both --width "$width" "$TMPDIR/left" "$TMPDIR/right" || true
    '';
  };

  # Translates jj-style arguments into revdiff positionals ([base] [against])
  # so the diff direction matches jj:
  #   jj review                  working copy changes (revdiff default)
  #   jj review REV              what REV introduces, like `jj show REV`
  #   jj review --from X --to Y  like `jj diff` (either side defaults to @)
  jj-review = pkgs.writeShellApplication {
    name = "jj-review";
    text = ''
      from="" to="" rev=""
      passthrough=()

      while [ $# -gt 0 ]; do
        case "$1" in
          --from) from="''${2:?--from needs a revision}"; shift ;;
          --from=*) from="''${1#--from=}" ;;
          --to) to="''${2:?--to needs a revision}"; shift ;;
          --to=*) to="''${1#--to=}" ;;
          -*) passthrough+=("$1") ;;
          *)
            if [ -n "$rev" ]; then
              echo "jj review: use --from/--to to compare two revisions" >&2
              exit 2
            fi
            rev="$1"
            ;;
        esac
        shift
      done

      if [ -n "$rev" ] && { [ -n "$from" ] || [ -n "$to" ]; }; then
        echo "jj review: pass either a revision or --from/--to, not both" >&2
        exit 2
      fi

      if [ -n "$rev" ]; then
        from="($rev)-"
        to="$rev"
      fi

      if [ -n "$from" ] || [ -n "$to" ]; then
        exec ${config.eget.path}/revdiff "''${from:-@}" "''${to:-@}" "''${passthrough[@]}"
      fi

      exec ${config.eget.path}/revdiff "''${passthrough[@]}"
    '';
  };
in {
  config = mkIf config.developer-tools.enable {
    # jj diff/split tools, not yet in nixpkgs
    eget.packages = [
      "emilien-jegou/oyui"
      "umputun/revdiff"
    ];

    home = {
      sessionPath = [
        "$HOME/.cargo/bin"
        "$HOME/go/bin"
      ];

      # Generated from the current scheme by a tinty hook (see theme.nix)
      sessionVariables.REVDIFF_THEME = "tinty";

      packages = with pkgs;
      # All systems
        [
          yq-go
          jq
          shellcheck

          nix-prefetch
          terminaltexteffects

          wrap
          fselect # Find, but with SQL
          wiper # Disk usage TUI

          tcping-go

          # LSPs
          nil
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
          dlo9.elio # TUI file manager
          dlo9.croft # TUI vscode thing?
          otree # JSON tree viewer
          somo

          #flashrom
          #noseyparker # Credential scanner
          #vulnix # Vulnerability scanner

          mdfried # Markdown reader
          trippy # Network diagnostics
          inxi # Hardware info

          # CSV utils
          miller
          csvlens

          fastmod # Search & replace tool
          ast-grep # AST search & replace
          mcat
          mosh
          jjui

          git-filter-repo
          nodejs_24 # Needed for claude code in vscode

          #diff-so-fancy
          difftastic
          lnav # Log file viewer

          gh
        ]
        ++
        # Linux only
        (optionals isLinux [
          isd
          (dlo9.rustnet.override {rustPlatform = pkgs.unstable.rustPlatform;})
          unstable.claude-code
          android-tools # adb
        ]);
    };

    programs = {
      zellij.enable = false;

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

      fresh-editor = {
        enable = true;
        defaultEditor = false;
      };

      jujutsu = {
        enable = true;
        package = pkgs.unstable.jujutsu;
        settings = {
          user = config.programs.git.settings.user;

          remotes.origin.auto-track-bookmarks = "glob:*";

          git = {
            private-commits = let
              prefixes = concatStringsSep "|" ["private" "wip" "broken"];
            in "description(regex:'^(${prefixes}):') | bookmarks(regex:'^(${prefixes})-')";
          };

          aliases = {
            # Abandon descriptionless, empty commits
            abandon-empty = ["abandon" "-r" "empty() & mutable() & mine() & ~@"];

            # Create a new commit at the beginning of this branch
            prepend = ["new" "-B" "roots(trunk()..@)"];

            # Fetch and rebase
            update = ["util" "exec" "--" "sh" "-c" "jj git fetch && jj rebase -b @ -d 'trunk()'"];

            # Log all
            ll = ["log" "-r" "all()"];

            blame = ["file" "annotate"];

            # Review TUI: `jj review` (smart default), `jj review main`,
            # `jj review --from X --to Y` (see the jj-review wrapper above).
            # revdiff resolves jj revisions natively, so it isn't subject to
            # jj piping diff tool stdout through the pager (it renders on
            # /dev/tty), and shows the whole changeset with a file tree
            review = ["util" "exec" "--" "${jj-review}/bin/jj-review"];
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

          merge-tools = {
            # Diff editor: jj split/diffedit/commit -i/squash -i --tool oyui.
            # Editor only: `jj diff --tool oyui` can't work since jj pipes a
            # diff tool's stdout through the pager, which garbles TUIs
            oyui = {
              program = "${config.eget.path}/oyui";
              edit-args = ["diff" "$left" "$right"];
            };
          };

          signing = {
            backend = config.programs.git.settings.gpg.format;
            key = config.programs.git.settings.user.signingkey;
            behavior = "own";
          };

          ui = {
            # Decrypt sops files before diffing
            diff-formatter = ["${jj-sops-diff}/bin/jj-sops-diff" "$left" "$right"];
            #merge-editor = "mergiraf";
            diff-editor = "oyui";

            # oyui shows its own help instead of the JJ-INSTRUCTIONS file
            diff-instructions = false;
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
