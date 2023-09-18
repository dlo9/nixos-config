{
  lib,
  pkgs,
  hostName,
  inputs,
  ...
}:
with lib;
with types; let
  hostYaml = host: "${inputs.self}/hosts/${host}/secrets.yaml";
  hostYamlExists = host: pathExists (hostYaml host);

  hosts = attrNames (filterAttrs (name: value: value == "directory" && (hostYamlExists name)) (builtins.readDir ./.));

  jsonTrace = value: builtins.trace (builtins.toJSON value) value;

  importExports = sopsFile: let
    # mapExports = baseName: name: value: {
    #   inherit value;
    #   name = "${baseName}-${name}";
    # };
    attrToExports = mapAttrs' (
      name: value: {
        inherit name;
        # value = mapAttrs' (mapExports name) value.exports;
        value = value.exports;
      }
    );

    isEnabled = name: value:
      (value.enable or false)
      && (builtins.isAttrs (value.exports or ""));

    contents = pkgs.fromYAML sopsFile;
    enabledContents = filterAttrs isEnabled contents;
  in
    attrToExports enabledContents;

  importSecrets = sopsFile: let
    attrToSecrets = mapAttrs' (
      # TODO: doesn't work with empty contents?
      key: value: {
        name = "${key}/contents";
        value = (value.sopsNix or {}) // {inherit sopsFile;};
      }
    );

    isEnabled = name: value:
      (value.enable or false)
      && (value ? contents);

    contents = pkgs.fromYAML sopsFile;
    enabledContents = filterAttrs isEnabled contents;
  in
    attrToSecrets enabledContents;
in {
  options = {
    hostExports = mkOption {
      description = "exported host configurations";
      type = attrsOf anything;
    };
  };

  config = {
    networking.hostName = hostName;

    # Set secrets for the current host
    sops.secrets = optionalAttrs (hostYamlExists hostName) (importSecrets (hostYaml hostName));

    # Export values for all hosts
    hostExports = builtins.listToAttrs (
      map (host: {
        name = host;
        value = importExports (hostYaml host);
      })
      hosts
    );
  };
}
