{
  lib,
  pkgs,
  hostname,
  inputs,
  mylib,
  ...
}:
with lib;
with types; {
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
    hosts = mylib.secrets.hostExports;
  };
}
