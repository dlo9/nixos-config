{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.developer-tools.enable {
    home = {
      sessionPath = [
        "$HOME/.cargo/bin"
      ];

      packages = with pkgs; [
        # Rust
        rustup

        yq-go
        jq
        shellcheck
      ];
    };
  };
}
