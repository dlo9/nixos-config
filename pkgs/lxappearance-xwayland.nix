{
  runCommand,
  makeWrapper,
  lxappearance,
}:

  # lxappearance is an x11 application, and crashes on wayland unless forced to use xwayland

      # TODO: can also be done like this, which symlinks all files instead of folders. Figure out which to use long-term
      # symlinkJoin {
      #   name = "lxappearance-xwayland";
      #   paths = [ lxappearance ];
      #   buildInputs = [ makeWrapper ];
      #   postBuild = ''
      #     wrapProgram "$out/bin/lxappearance" \
      #       --set-default GDK_BACKEND x11
      #   '';
      # };
runCommand "lxappearance"
        {
          buildInputs = [ makeWrapper ];
        } ''
        in="${lxappearance}"
        mkdir "$out"

        # Link every top-level folder from pkgs.lxappearance to our new target
        ln -s "$in"/* "$out"

        # Except the bin folder
        rm "$out/bin"
        mkdir "$out/bin"

        # We create the bin folder ourselves and link every binary in it
        ln -s "$in/bin/"* "$out/bin"

        # Except the lxappearance binary
        rm "$out/bin"/lxappearance

        # Because we create this ourself, by creating a wrapper
        makeWrapper "$in/bin/lxappearance" "$out/bin/lxappearance" \
          --set-default GDK_BACKEND x11
      ''
