{lib, ...}:
with lib; {
  options = {
    font.family = mkOption {
      type = types.nonEmptyStr;
      default = "NotoSansM Nerd Font Mono";
      # default = "B612";
    };

    font.size = mkOption {
      type = types.ints.positive;
      default = 14;
    };
  };
}
