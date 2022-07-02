!#/bin/sh

set -e

usage() {
    cat <<- EOF
    ./wifi.sh <name> <password>
EOF
}


# Manually connect to wireless network (wifi)
wifi_name="$1"
wifi_password="$2"
wifi_interface="$(ip link show | awk -F '[ \t:]+' ' $2 ~ /^w/ { print $2 }')"

if [ -z "$wifi_name" ] || [ -z "$wifi_password" ]; then
  usage
  exit 1
fi

trap "rm -f /tmp/wifi_config" EXIT INT
wpa_passphrase "$wifi_name" "$wifi_password" > /tmp/wifi_config
wpa_supplicant -i "$wifi_interface" -c /tmp/wifi_config

