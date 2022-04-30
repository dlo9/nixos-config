{ config, pkgs, ... }:

{
  # To add a printer, go to:
  # http://localhost:631/
  services.printing.enable = true;
  services.printing.drivers = [
    # See other drivers at https://nixos.wiki/wiki/Printing
    # Brother drivers
    pkgs.brgenml1lpr
    pkgs.brgenml1cupswrapper
  ];

  services.avahi.enable = true;
  services.avahi.nssmdns = true;
}
