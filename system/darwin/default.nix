{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./nix.nix
    ./skhd.nix
    ./spacebar.nix
    ./system-settings.nix
    ./yabai.nix
  ];
}
