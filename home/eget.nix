# Installs github-released binaries which aren't in nixpkgs: on activation,
# each repo in `eget.packages` is downloaded into `eget.path` with eget.
# eget only downloads when the release is newer than the installed binary
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  # eget only honours asset_filters in per-repo sections, not [global]
  egetConfig = (pkgs.formats.toml {}).generate "eget.toml" (
    genAttrs config.eget.packages (_: {asset_filters = config.eget.assetFilters;})
  );
in {
  options.eget = {
    packages = mkOption {
      type = types.listOf types.nonEmptyStr;
      default = [];
      description = ''
        GitHub repos (owner/repo) whose release binaries to install with
        eget on activation. Binaries are only downloaded when the release
        is newer than the installed copy.
      '';
    };

    path = mkOption {
      type = types.nonEmptyStr;
      default = "${config.home.homeDirectory}/.local/bin";
      description = "Directory eget installs binaries into; added to the session PATH";
    };

    system = mkOption {
      type = types.nonEmptyStr;
      default = with pkgs.stdenv.hostPlatform.go; "${GOOS}/${GOARCH}";
      description = ''
        GOOS/GOARCH pair eget picks release assets for. Defaults to the
        system nix is building for, rather than the one the eget binary
        itself was built for. Use "all" to pick assets interactively.
      '';
    };

    assetFilters = mkOption {
      type = types.listOf types.nonEmptyStr;
      default = ["^.deb" "^.rpm"];
      description = ''
        Asset filters applied to every eget package, for releases that
        publish several equivalent assets per system (a `^` prefix
        anti-matches). The default skips distro packaging in favour of
        plain archives.
      '';
    };
  };

  config = {
    home.sessionPath = [config.eget.path];

    home.activation = mkIf (config.eget.packages != []) {
      eget-tools = hm.dag.entryAfter ["writeBoundary"] ''
        run mkdir -p ${escapeShellArg config.eget.path}

        for repo in ${escapeShellArgs config.eget.packages}; do
          # stdin is closed so that a repo with no asset for this system fails
          # instead of prompting for a manual selection
          run env EGET_CONFIG=${egetConfig} ${pkgs.eget}/bin/eget "$repo" --to ${escapeShellArg config.eget.path} \
            --system ${escapeShellArg config.eget.system} --upgrade-only < /dev/null \
            || warnEcho "eget: failed to install $repo (no ${config.eget.system} asset?)"
        done
      '';
    };
  };
}
