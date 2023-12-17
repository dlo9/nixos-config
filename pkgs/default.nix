{pkgs}:
with pkgs; {
  vimPlugins = recurseIntoAttrs (callPackage ./vim-plugins {});
  tmuxPlugins = recurseIntoAttrs (callPackage ./tmux-plugins {});
  lib = recurseIntoAttrs (callPackage ./lib {});

  flatcolor-gtk-theme = callPackage ./flatcolor-gtk-theme.nix {};
  lxappearance-xwayland = callPackage ./lxappearance-xwayland.nix {};

  nss-docker = callPackage ./nss-docker.nix {};
  caddy = callPackage ./caddy.nix {};
}
