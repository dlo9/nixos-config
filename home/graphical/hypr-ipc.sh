#!/usr/bin/env bash
# https://wiki.hyprland.org/IPC/

handle() {
  active=$(hyprctl activewindow -j)
  clients=$(hyprctl clients -j)

  case $1 in
    "fullscreen>>1")
    #   address="$(echo "$clients" | jq ".[] | select((.title | test(\"Tree Style Tab\") and .fullscreen).address")"
      address="$(echo "$active" | jq "select(.title | test(\"Tree Style Tab\")).address")"

      if [ -n "$address" ]; then
        hyprctl dispatch fullscreen
      fi
    ;;

    windowtitle*)
      # shellcheck disable=SC2001
      address="0x$(echo "$1" | sed 's#^.*>>##')"
      title="$(echo "$clients" | jq ".[] | select(.address==\"$address\" and (.floating | not)).title")"

      if echo "$title" | grep "Tree Style Tab" >/dev/null; then
        hyprctl dispatch togglefloating "address:$address"
        hyprctl dispatch centerwindow "address:$address"
        hyprctl dispatch focuswindow "address:$address"
      fi
    ;;
  esac
}

# Kill existing script
pidfile=/tmp/hypr-ipc.pid
if [ -f "$pidfile" ]; then
    kill "$(cat "$pidfile")" || true
fi

# Record current PID
echo "$$" > "$pidfile"

# Listen to events
socat -U - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
