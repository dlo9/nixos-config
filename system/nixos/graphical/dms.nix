{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.graphical.enable {
    # DankMaterialShell: a Quickshell desktop shell. `pkgs.dms` is an unrelated
    # DLNA media server; the shell and its CLI are `pkgs.dms-shell`.
    #
    # The module writes no compositor config (upstream's `dms setup` does that
    # for non-declarative users), so keybinds live alongside every other bind
    # in home/graphical/hyprland.nix.
    programs.dms-shell = {
      enable = true;

      # Not the default graphical-session.target: the shell needs
      # HYPRLAND_INSTANCE_SIGNATURE and WAYLAND_DISPLAY in the user environment
      # first. Mirrors `wayland.systemd.target` on the home side.
      systemd.target = "hyprland-session.target";
    };

    # power-profiles-daemon, on by default from the module to back its power
    # profile widget, asserts against tlp. Let tlp win where it's set; the
    # widget is the only thing lost.
    services.power-profiles-daemon.enable = mkIf config.services.tlp.enable (mkForce false);

    # DMS reads battery state only from UPower over DBus, so without the daemon
    # it believes it's on a desktop: no charge level, AC idle timeouts applied
    # on battery, and no automatic ac/battery power profile switching. Waybar
    # read /sys/class/power_supply directly, which is why nothing enabled this
    # before; the upstream module doesn't pull it in either (it pulls in
    # power-profiles-daemon, a confusingly-named neighbour, not UPower).
    services.upower.enable = mkDefault true;

    # DMS's daemon opens /dev/input/event* directly to watch the Caps Lock LED,
    # the only thing its evdev manager is used for; without the group the Caps
    # Lock OSD and bar indicator go quiet. `dms setup` does this with usermod.
    #
    # Note this grants read access to every input device, so anything running
    # as this user can read keystrokes system-wide, not just its own window's.
    # That's the standing cost of the OSD.
    #
    # Guarded on the whole attrset rather than the value: mkIf defers its
    # content, but an attribute *name* of ${null} would throw before it got
    # there.
    users.users = mkIf (config.mainAdmin != null) {
      ${config.mainAdmin}.extraGroups = ["input"];
    };

    # The lock screen uses /etc/pam.d/dankshell when it exists and silently
    # falls back to `login` otherwise. Its own service lets lockscreen auth
    # diverge from console login.
    security.pam.services.dankshell = {};

    ###################
    ##### Greeter #####
    ###################
    #
    # Off by default; without it the session starts from getty autologin plus
    # the `exec start-hyprland` in home/graphical/hyprland.nix.
    #
    # Turning it on does NOT add a password prompt at boot: autoLogin for
    # mainAdmin becomes greetd's `initial_session`. The greeter appears on
    # logout or user switch. Same `start-hyprland` supervisor either way, but
    # the journal identifier becomes `start-hyprland`, since the module wraps
    # it in its own systemd-cat.
    services.displayManager.dms-greeter = mkIf config.dms.greeter.enable {
      enable = true;
      compositor.name = "hyprland";

      # Copied into /var/lib/dms-greeter at greetd start, so the login screen
      # inherits the session's wallpaper, palette and settings.
      configHome = config.users.users.${config.mainAdmin}.home;
    };

    # Hyprland is otherwise driven entirely from home-manager, but the greeter
    # asserts on the system module: it needs programs.hyprland.package plus the
    # session file that makes the autologin session resolvable.
    programs.hyprland.enable = mkIf config.dms.greeter.enable true;

    # greetd takes tty1; getty autologin would race it for the same terminal.
    services.getty.autologinUser = mkIf config.dms.greeter.enable null;
  };
}
