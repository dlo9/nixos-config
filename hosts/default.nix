{
  lib,
  pkgs,
  hostname,
  inputs,
  ...
}:
with lib;
with types; let
  hostYaml = host: "${inputs.self}/hosts/${host}/secrets.yaml";
  hostYamlExists = host: pathExists (hostYaml host);

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

  importSecrets = sopsFile: let
    attrToSecrets = mapAttrs' (
      name: value: {
        inherit name;

        value =
          (value.sopsNix or {})
          // {
            inherit sopsFile;
            key = "${name}/contents";
          };
      }
    );

    isEnabled = name: value:
      (value.enable or false)
      && (value ? contents);

    contents = pkgs.dlo9.lib.fromYAML sopsFile;
    enabledContents = filterAttrs isEnabled contents;
  in
    attrToSecrets enabledContents;
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
    networking.hostName = hostname;

    # Set secrets for the current host
    sops.secrets = optionalAttrs (hostYamlExists hostname) (importSecrets (hostYaml hostname));

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
