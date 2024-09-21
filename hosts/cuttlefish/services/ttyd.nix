{config, ...}: {
  # Web shell
  services.ttyd = {
    enable = true;
    writeable = true;

    port = 7681;
    interface = "lo";
    clientOptions = {
      fontFamily = config.font.family;
      fontSize = builtins.toString config.font.size;
    };
  };
}
