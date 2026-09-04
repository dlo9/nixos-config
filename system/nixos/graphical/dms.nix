{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf (config.graphical.enable && config.dms.enable) {
    # DankMaterialShell: a Quickshell desktop shell providing the bar, launcher
    # (spotlight), notification daemon, lock screen, wallpaper, clipboard
    # history, OSDs, control center and idle/power management.
    #
    # The module installs the shell and its `dms` CLI. Note that `pkgs.dms` is
    # an unrelated DLNA media server -- the CLI this config drives ships inside
    # `pkgs.dms-shell`, which is what `programs.dms-shell.package` points at.
    #
    # The module deliberately writes no compositor config (upstream's `dms
    # setup` does that for non-declarative users), so keybinds live alongside
    # every other bind in home/graphical/hyprland.nix.
    programs.dms-shell = {
      enable = true;

      # Start with Hyprland's session rather than the default
      # graphical-session.target, so the shell only comes up once
      # HYPRLAND_INSTANCE_SIGNATURE and WAYLAND_DISPLAY have been imported into
      # the systemd user environment. Mirrors `wayland.systemd.target` on the
      # home side.
      systemd.target = "hyprland-session.target";
    };

    # The module turns on power-profiles-daemon by default to back its power
    # profile widget, but that asserts against tlp, which the laptops here use
    # instead (hosts/{cuttlefish,pavil}/hardware). Let tlp win where it's set;
    # the widget is the only thing lost.
    services.power-profiles-daemon.enable = mkIf config.services.tlp.enable (mkForce false);

    # Battery state comes from UPower over DBus and nowhere else
    # (Services/BatteryService.qml imports Quickshell.Services.UPower), so
    # without the daemon `batteries` is empty and the shell believes it's on a
    # desktop. Waybar never needed this -- its battery module reads
    # /sys/class/power_supply directly -- which is why nothing here enabled it
    # before. The upstream dms-shell module doesn't pull it in either, though it
    # does pull in power-profiles-daemon; that daemon owns
    # org.freedesktop.UPower.PowerProfiles, which is a confusingly-named
    # neighbour of UPower rather than UPower itself.
    #
    # Two things break quietly without it beyond the missing charge level:
    # IdleService gates its battery timeouts on `batteryAvailable`, so the AC
    # timeouts apply on battery too, and BatteryService's automatic
    # ac/batteryProfileName switching hangs off a plugged-in state that never
    # changes.
    services.upower.enable = mkDefault true;

    # DMS's Go daemon opens /dev/input/event* directly to watch for the Caps
    # Lock LED -- it's what drives Modules/OSD/CapsLockOSD.qml and the
    # CapsLockIndicator bar widget, and it's the only thing the evdev manager
    # is used for. Without the group it logs "Failed to initialize evdev
    # manager: insufficient permissions to access input devices" at startup and
    # both go quiet; upstream's own message for the same case is "Could not add
    # %s to input group (Caps Lock OSD will be unavailable)". `dms setup` does
    # this imperatively with usermod, which is the non-declarative path.
    #
    # Note this grants read access to every input device, so anything running
    # as this user can read keystrokes system-wide, not just its own window's.
    # That's the standing cost of the OSD.
    # Guarded on the whole attrset rather than the value: mkIf defers its
    # content, but an attribute *name* of ${null} would throw before it got
    # there.
    users.users = mkIf (config.mainAdmin != null) {
      ${config.mainAdmin}.extraGroups = ["input"];
    };

    # The lock screen authenticates against /etc/pam.d/dankshell when it exists
    # and silently falls back to `login` otherwise (Modules/Lock/Pam.qml). Give
    # it its own service so lockscreen auth can diverge from console login.
    security.pam.services.dankshell = {};

    ###################
    ##### Greeter #####
    ###################
    #
    # There is no login screen today: whole-disk encryption already gates the
    # machine, so the session starts from getty autologin plus the
    # `exec start-hyprland` in fish's login shell init (home/graphical/hyprland.nix).
    #
    # Turning this on replaces that path with greetd. It does NOT add a
    # password prompt at boot: services.displayManager.autoLogin is already on
    # for mainAdmin, which the greeter module turns into a greetd
    # `initial_session`, so first boot still goes straight to the desktop. The
    # greeter appears when you log out or switch users.
    #
    # The supervisor survives the move -- `start-hyprland` is Hyprland's own
    # binary and is already the `Exec=` in its hyprland.desktop, which is what
    # greetd resolves the autologin command from. The one difference is the
    # journal identifier: `start-hyprland` rather than `hyprland-session`, as
    # the module wraps it in its own systemd-cat.
    services.displayManager.dms-greeter = mkIf config.dms.greeter.enable {
      enable = true;
      compositor.name = "hyprland";

      # Copies settings.json, session.json and dms-colors.json into
      # /var/lib/dms-greeter at greetd start, so the login screen inherits the
      # wallpaper, Material palette and shell settings from the session.
      configHome = config.users.users.${config.mainAdmin}.home;
    };

    # Hyprland is otherwise driven entirely from home-manager. The greeter
    # asserts on the system module: it needs programs.hyprland.package to
    # launch the compositor, and the session package it installs is what makes
    # the autologin session resolvable.
    programs.hyprland.enable = mkIf config.dms.greeter.enable true;

    # greetd takes tty1, so getty autologin would be racing it for the same
    # terminal. Boot still lands in the session via greetd's initial_session.
    services.getty.autologinUser = mkIf config.dms.greeter.enable null;
  };
}
