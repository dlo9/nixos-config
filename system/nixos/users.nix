{
  pkgs,
  lib,
  ...
}: {
  # Users
  users.mutableUsers = false;
  users.users = {
    root.hashedPassword = "$6$0/6kZLj/YlKMK7c5$eW4UjS1OE6OtEt9DI6JoeUkc8xi3eLDE2xc4/nD50L8NPYU7m5QpCxPVAYLF2t.hw76Z5/LR7uJztN8fjDVqq.";

    david = {
      uid = 1000;
      isNormalUser = true;
      hashedPassword = "$y$j9T$PcYhxYODK1jqn8tcCRWa1/$XCP99oOMrsQ7xMXzswZ7hypbIXKQ2YNXh2L7vTjteD6";
      createHome = true;
      shell = pkgs.fish;
      extraGroups = [
        "wheel"
        "docker"
        "podman"
        "audio"
        "video"
        "adbusers" # Android ADB
        "scanner" # Scanning
        "lp" # Printing
        "libvirtd"
      ];
    };
  };

  adminUsers = ["david"];
}
