# Taken from: https://github.com/yunfachi/nypkgs/blob/698ab4159dc38affee2fc5886468af139de8d95e/lib/umport.nix
{lib, ...}: let
  umport = {
    path ? null,
    paths ? [],
    include ? [],
    exclude ? [],
    recursive ? true,
  }:
    with lib;
    with fileset; let
      excludedFiles = filter (path: pathIsRegularFile path) exclude;
      excludedDirs = filter (path: pathIsDirectory path) exclude;
      isExcluded = path:
        if elem path excludedFiles
        then true
        else (filter (excludedDir: lib.path.hasPrefix excludedDir path) excludedDirs) != [];
    in
      unique (
        (
          filter
          (file: pathIsRegularFile file && hasSuffix ".nix" (builtins.toString file) && !isExcluded file)
          (concatMap (
              _path:
                if recursive
                then toList _path
                else
                  mapAttrsToList (
                    name: type:
                      _path
                      + (
                        if type == "directory"
                        then "/${name}/default.nix"
                        else "/${name}"
                      )
                  )
                  (builtins.readDir _path)
            )
            (unique (
              if path == null
              then paths
              else [path] ++ paths
            )))
        )
        ++ (
          if recursive
          then concatMap (path: toList path) (unique include)
          else unique include
        )
      );
in {
  inherit umport;
}
