{
  runCommand,
  yj,
}: yamlFile:
builtins.fromJSON (
  builtins.readFile (
    runCommand "from-yaml"
    {
      allowSubstitutes = false;
      preferLocalBuild = true;
    }
    ''
      ${yj}/bin/yj -yj < "${yamlFile}" > "$out"
    ''
  )
)
