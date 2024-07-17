{
  lib,
  pkgs,
  hostname,
  inputs,
  ...
}:
with lib;
with types; let
  # Put the file in the store, so that the derivation doesn't change every time.
  # Otherwise, the file path changes each time anything in the repo changes,
  # delaying build times
  # TODO: only change if it ends in `-source`?
  store = f: builtins.toFile "contents" (builtins.readFile f);

  # TODO: this is duplicated
  hostYamlPath = host: "${inputs.self}/hosts/${host}/secrets.yaml";
  hostYaml = host: store (hostYamlPath host);
  hostYamlExists = host: pathExists (hostYamlPath host);

  hosts = attrNames (filterAttrs (name: value: value == "directory" && (hostYamlExists name)) (builtins.readDir ./.));

  importExports = sopsFile: let
    attrToExports = mapAttrs' (
      name: value: {
        inherit name;
        value = value.exports;
      }
    );

    isEnabled = name: value:
      (value.enable or false)
      && (builtins.isAttrs (value.exports or ""));

    contents = pkgs.dlo9.lib.fromYAML sopsFile;
    enabledContents = filterAttrs isEnabled contents;
  in
    attrToExports enabledContents;
in {
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
    hosts = builtins.listToAttrs (
      map (host: {
        name = host;
        value = importExports (hostYaml host);
      })
      hosts
    );
  };
}
