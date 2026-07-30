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
}
