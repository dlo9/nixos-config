{name, ...}: {
  options = {
    name = mkOption {
      description = "Hostname";
      type = nonEmptyStr;
      default = name;
      readOnly = true;
    };

    users = mkOption {
      description = "exported host configurations";
      type = attrsOf (submodule (import ./user.nix));
    };
  };
}
