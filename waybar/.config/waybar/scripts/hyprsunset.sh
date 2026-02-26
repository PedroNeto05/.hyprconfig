#!/usr/bin/env bash
set -u

is_running() {
  pgrep -x hyprsunset >/dev/null 2>&1
}

if [ "${1:-}" = "toggle" ]; then
  if is_running; then
    pkill -x hyprsunset >/dev/null 2>&1
  else
    hyprsunset >/dev/null 2>&1 &
  fi
  exit 0
fi

if [ "${1:-}" = "status" ]; then
  if is_running; then
    echo '{"text":"","class":"warm"}'
  else
    echo '{"text":"󰖨","class":"off"}'
  fi
  exit 0
fi

# fallback (NUNCA fica sem output)
echo '{"text":"󰛨","class":"off"}'
