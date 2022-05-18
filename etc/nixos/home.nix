{ config, pkgs, ... }:

# Home manager configuration
# - Manual: https://nix-community.github.io/home-manager/index.html#sec-install-nixos-module
# - Config: https://rycee.gitlab.io/home-manager/options.html

{
  programs = {
    git = {
      enable = true;
      userName = "David Orchard";
      userEmail = "if_coding@fastmail.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.ff = "only";
      };
    };
  };
}

