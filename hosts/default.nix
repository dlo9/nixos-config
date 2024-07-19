{
  lib,
  pkgs,
  hostname,
  inputs,
  ...
}:
with lib;
with types;
with pkgs.dlo9.lib; {
  imports = [
    "${inputs.self}/hosts/${hostname}"
  ];

  options = {
    hosts = mkOption {
      description = "exported host configurations";
      type = attrsOf anything;
    };
  };

  config = {
    # Export values for all hosts
    hosts = secrets.hostExports;
  };
}
