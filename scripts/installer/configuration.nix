{ pkgs, ... }: {
  imports = [ /etc/nixos/configuration.nix ];

  # Use flakes -- see flake.nix for real config
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment = {
    enableAllTerminfo = true;
    systemPackages = with pkgs; [
      expect
    ];
  };
}
