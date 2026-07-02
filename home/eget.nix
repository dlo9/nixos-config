# Installs github-released binaries which aren't in nixpkgs: on activation,
# each repo in `eget.packages` is downloaded into `eget.path` with eget.
# eget only downloads when the release is newer than the installed binary
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  home.sessionPath = [config.eget.path];

  home.activation = mkIf (config.eget.packages != []) {
    eget-tools = hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p ${escapeShellArg config.eget.path}

      for repo in ${escapeShellArgs config.eget.packages}; do
        run ${pkgs.eget}/bin/eget "$repo" --to ${escapeShellArg config.eget.path} --upgrade-only \
          || warnEcho "eget: failed to install $repo"
      done
    '';
  };
}
