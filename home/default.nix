# Home manager configuration
# - Manual: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
# - Config: https://rycee.gitlab.io/home-manager/options.html
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; {
  imports = [
    ./cli
    ./graphical
    ./options.nix
    ./theme.nix
  ];

  home = {
    stateVersion = "22.05";

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
