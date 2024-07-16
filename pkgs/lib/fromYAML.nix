{
  runCommand,
  yj,
}: yamlFile: let
  # Put the file in the store, so that the derivation doesn't change every time.
  # Otherwise, the file path changes each time anything in the repo changes,
  # delaying build times
  inputFile = builtins.toFile "input.yaml" (builtins.readFile yamlFile);
in
  builtins.fromJSON (
    builtins.readFile (
      runCommand "from-yaml"
      {
        allowSubstitutes = false;
        preferLocalBuild = true;
      }
      ''
        ${yj}/bin/yj -yj < "${inputFile}" > "$out"
      ''
    )
  )
