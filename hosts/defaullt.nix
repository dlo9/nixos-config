{
  lib,
  pkgs,
  ...
}:
with lib;
with types; let
  # Recurse into an attrSet until a non-attrset is encountered.
  # Then, remove the prefix from the attribute's name
  removeLeafPrefix = attr: prefix: let
    recurse = attr:
      mapAttrs' (
        name: value:
          if builtins.isAttrs value
          then recurse value
          else {
            inherit value;
            name = removePrefix prefix name;
          }
      );
  in
    recurse attr;

  # Import all leaf keys starting with `_` into an attribute set
  importHostSecrets = host: let
    isExportedValue = name: value: (hasPrefix "_" name) || builtins.isAttrs value;
    hostSecrets = fromYAML "./${host}/secrets.yaml";
  in
    removeLeafPrefix (filterAttrsRecursive isExportedValue hostSecrets);

  # TODO: Use a dynamic list for all hosts
  hosts = [
    "cuttlefish"
    "drywell"
    "installer-test"
    "mallow"
    "nib"
    "pavil"
    "rpi3"
  ];
in {
  options.hosts = mkOption {
    description = "exported host configurations";
    # type = attrsOf (submodule (import ./host.nix));
    type = attrsOf anything;
  };

  config.hosts = builtins.listToAttrs (
    map (host: {
      name = host;
      value = importHostSecrets host;
    })
    hosts
  );
}
