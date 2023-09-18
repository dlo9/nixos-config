{
  lib,
  pkgs,
  hostName,
  inputs,
  ...
}:
with lib;
with types; let
  hosts = attrNames (filterAttrs (n: v: v == "directory") (builtins.readDir ./.));

  importExports = sopsFile: let
    fileToExports = mapAttrs' (
      key: value:
        if (builtins.isAttrs value && (value.enable or false))
        then (value.exports or {})
        else {}
    );
    removeNulls = filterAttrs (name: value: value != null);
    contents = pkgs.fromYAML sopsFile;
  in
    removeNulls (fileToExports contents);

  importSecrets = sopsFile: let
    fileToSecrets = mapAttrs' (
      key: value:
        if (builtins.isAttrs value && (value.enable or false))
        then {"${key}/contents" = value.attrs // {inherit sopsFile;};}
        else null
    );
    removeNulls = filterAttrs (name: value: value != null);
    contents = pkgs.fromYAML sopsFile;
  in
    removeNulls (fileToSecrets contents);
in {
  options = {
    hostExports = mkOption {
      description = "exported host configurations";
      type = attrsOf anything;
    };
  };

  config = {
    networking.hostName = hostName;

    sops.secrets = importSecrets "${inputs.self}/hosts/${hostName}/secrets.yaml";

    hostExports = builtins.listToAttrs (
      map (host: {
        name = host;
        value = importExports "${inputs.self}/hosts/${host}/secrets.yaml";
      })
      hosts
    );
  };
}
