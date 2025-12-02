# Home manager configuration
# - Manual: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
# - Config: https://rycee.gitlab.io/home-manager/options.html
{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  ...
}:
with lib; {
  imports = [
    ./cli
    ./graphical
    ./options.nix
    ./theme.nix

    inputs.flake-programs-sqlite.homeModules.programs-sqlite
  ];

  nix.gc = {
    automatic = true;
    dates = "daily";
  };

  programs.command-not-found.enable = true;

  programs.fish.interactiveShellInit = mkAfter ''
    # The command-no-found DB doesn't support darwin, so pretend darwin systems are linux
    # by wrapping fish_command_not_found with a linux NIX_SYSTEM
    functions -c fish_command_not_found __fish_command_not_found

    function fish_command_not_found
      set -lx NIX_SYSTEM "${lib.replaceString "darwin" "linux" pkgs.stdenv.hostPlatform.system}"

      __fish_command_not_found $argv
    end
  '';

  programs.nix-index = {
    enable = false;
    enableFishIntegration = config.programs.fish.enable;
  };

  services.home-manager.autoExpire = {
    enable = isLinux;
    store.cleanup = true;
    frequency = "daily";
    timestamp = "-7 days";
  };

  home = {
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.wrap/shims"
    ];

    sessionVariables = {
      SOPS_AGE_KEY_FILE = "/var/sops-age-keys.txt";
    };

    file = {
      ".wrap/generate.sh".text = ''
        #!/bin/sh

        set -e

        dir="$(dirname "$0")"

        if [[ -z "$@" ]] || [[ -z "$dir" ]]; then
          echo "usage: generate.sh <wrap alias>..."
          exit 1
        fi

        for name in "$@"; do
          bin="$dir/shims/$name"

          printf "%s\n" "#!/bin/sh" "wrap $name \"\$@\"" > "$bin"
          chmod +x "$bin"
        done
      '';
    };
  };

  # Allow user-installed fonts
  fonts.fontconfig.enable = true;

  xdg = {
    enable = mkDefault true;

    configFile = {
      "nixpkgs/config.nix".text = ''
        {
          allowUnfree = true;
        }
      '';

      "wrap.yaml".source = mkDefault ./wrap.yaml;
    };
  };
}
