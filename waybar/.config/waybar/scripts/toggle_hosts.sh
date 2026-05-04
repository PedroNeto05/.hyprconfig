#!/bin/bash
exec 2>/dev/null

readonly HOSTS_FILE="/etc/hosts"
readonly MARKER_START="# === SCRIPT BLOCK START ==="
readonly MARKER_END="# === SCRIPT BLOCK END ==="

readonly BASES=("x" "twitter" "youtube" "tiktok")
readonly TLDS=("com" "com.br" "net" "org" "tv")

send_notification() {
  local title="$1"
  local message="$2"

  local user_uid="${PKEXEC_UID:-${SUDO_UID:-$(id -u)}}"
  local user_name
  user_name="$(id -un "$user_uid")"

  sudo -u "$user_name" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${user_uid}/bus" \
    notify-send "$title" "$message" -t 3000 >/dev/null 2>&1
}

generate_variations() {
  local base="$1"

  echo "$base"
  for tld in "${TLDS[@]}"; do
    echo "${base}.${tld}"
    echo "www.${base}.${tld}"
  done
}

main() {
  if grep -q "$MARKER_START" "$HOSTS_FILE"; then
    sed -i "/^$MARKER_START$/,/^$MARKER_END$/d" "$HOSTS_FILE"
    systemctl restart systemd-resolved || true

    send_notification "Hosts Management" "Status: Unblocked"
  else
    {
      echo "$MARKER_START"
      for base in "${BASES[@]}"; do
        for domain in $(generate_variations "$base"); do
          echo "0.0.0.0 $domain"
        done
      done
      echo "$MARKER_END"
    } >>"$HOSTS_FILE"

    systemctl restart systemd-resolved || true

    send_notification "Hosts Management" "Status: Blocked"
  fi
}

main
