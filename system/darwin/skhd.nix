{
  services.skhd = let
    modifier = "alt";
  in {
    # Don't forget to disable "Secure Keyboard Entry" by opening the terminal application
    enable = true;
    skhdConfig = ''
      # To debug "secure keyboard entry" error:
      # https://github.com/koekeishiya/skhd/issues/48
      # ioreg -l -w 0 | perl -nle 'print $1 if /"kCGSSessionSecureInputPID"=(\d+)/' | uniq | xargs -I{} ps -p {} -o comm=

      # Focus window
      ${modifier} - left : yabai -m window --focus west || yabai -m display --focus west
      ${modifier} - right : yabai -m window --focus east || yabai -m display --focus east
      ${modifier} - up : yabai -m window --focus north || yabai -m display --focus north
      ${modifier} - down : yabai -m window --focus south || yabai -m display --focus south

      # Move managed window
      ${modifier} - space : yabai -m window --toggle split
      ${modifier} + shift - left : yabai -m window --swap west || (yabai -m window --display west && yabai -m display --focus west)
      ${modifier} + shift - right : yabai -m window --swap east || (yabai -m window --display east && yabai -m display --focus east)
      ${modifier} + shift - up : yabai -m window --swap north || (yabai -m window --display north && yabai -m display --focus north)
      ${modifier} + shift - down : yabai -m window --swap south || (yabai -m window --display south && yabai -m display --focus south)

      # Fullscreen
      ${modifier} - f : yabai -m window --toggle native-fullscreen
      ${modifier} + shift - f : yabai -m window --toggle zoom-fullscreen

      # Close
      ${modifier} + shift - q : yabai -m window --close

      # Terminal
      ${modifier} - return : ${pkgs.alacritty}/bin/alacritty

      # Resizing
      ${modifier} + ctrl - left : yabai -m window --resize left:-100:0 || yabai -m window --resize right:-100:0
      ${modifier} + ctrl - right : yabai -m window --resize right:100:0 || yabai -m window --resize left:100:0
      ${modifier} + ctrl - up : yabai -m window --resize top:0:-100 || yabai -m window --resize bottom:0:-100
      ${modifier} + ctrl - down : yabai -m window --resize bottom:0:100 || yabai -m window --resize top:0:100

      # Toggle focus & center window
      ${modifier} + shift - space : yabai -m window --toggle float && yabai -m window --grid 4:4:1:1:2:2 && yabai -m window --focus

      # Focus monitor
      ${modifier} - 1 : yabai -m display --focus 1
      ${modifier} - 2 : yabai -m display --focus 2
      ${modifier} - 3 : yabai -m display --focus 3

      # Send window to monitor
      ${modifier} + shift - 1 : yabai -m window --display 1 && yabai -m display --focus 1
      ${modifier} + shift - 2 : yabai -m window --display 2 && yabai -m display --focus 2
      ${modifier} + shift - 3 : yabai -m window --display 3 && yabai -m display --focus 3

      # Set split direction
      ${modifier} - v : yabai -m window --insert south
      ${modifier} - h : yabai -m window --insert east

      # Reset split ratio
      ${modifier} + ctrl - r : yabai -m window --ratio abs:0.5

      # Restart yabai
      ${modifier} + shift - r : pkill yabai; pkill spacebar

      # Enable/disable yabai tiling
      ${modifier} + shift - e : if [ "$(yabai -m config layout)" == "bsp" ]; then yabai -m config layout float; else yabai -m config layout bsp; fi

      # Toggle dock visibility
      cmd - d: osascript -e 'tell application "System Events" to set the autohide of the dock preferences to not (get the autohide of the dock preferences)'
    '';
  };
}
