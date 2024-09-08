inputs: final: prev:
with prev.pkgs; {
  dlo9 = {
    vimPlugins = recurseIntoAttrs (callPackage ./vim-plugins {});
    tmuxPlugins = recurseIntoAttrs (callPackage ./tmux-plugins {});
    lib = recurseIntoAttrs (callPackage ./lib {inherit inputs;});

    flatcolor-gtk-theme = callPackage ./flatcolor-gtk-theme.nix {};
    lxappearance-xwayland = callPackage ./lxappearance-xwayland.nix {};

    nss-docker = callPackage ./nss-docker.nix {};
    havn = callPackage ./havn.nix {};
    tiptop = callPackage ./tiptop.nix {};
    pvw = callPackage ./pvw.nix {};
    cidr = callPackage ./cidr.nix {};
    caddy = callPackage ./caddy.nix {};
    alvr = callPackage ./alvr.nix {};
    posting = callPackage ./posting.nix {};
    otree = callPackage ./otree.nix {};
    # rainfrog = callPackage ./rainfrog.nix {}; # Requires rust 1.80, currently in unstable
  };
}
