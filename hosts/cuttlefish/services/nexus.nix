{
  config,
  pkgs,
  ...
}: {
  services.nexus = {
    enable = true;
    home = "/services/nexus/data";
    listenPort = 8081;
  };
}
