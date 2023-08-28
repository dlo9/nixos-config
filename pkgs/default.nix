{
  lib,
  callPackage,
}:
with lib;
# let
#   dlo9 = {
#     email = "if_coding@fastmail.com";
#     github = "dlo9";
#     githubId = 7187117;
#     name = "David Orchard";
#   };
# in
  {
    vimPlugins = recurseIntoAttrs (callPackage ./vim-plugins {});
    tmuxPlugins = recurseIntoAttrs (callPackage ./tmux-plugins {});

    flatcolor-gtk-theme = callPackage ./flatcolor-gtk-theme.nix {};
    lxappearance-xwayland = callPackage ./lxappearance-xwayland.nix {};

    nss-docker = callPackage ./nss-docker.nix {};
    caddy = callPackage ./caddy.nix {};
    # lib = callPackage ./lib.nix { };
    # lib = recurseIntoAttrs (callPackage ./lib { });
  }
  // (recurseIntoAttrs (callPackage ./lib.nix {}))
