#!/bin/bash
status=$(playerctl status 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)

if [ "$status" = "Playing" ]; then
  class="playing"
  icon="󰐊"
elif [ "$status" = "Paused" ]; then
  class="paused"
  icon="󰏤"
else
  echo ""
  exit
fi

if [ -n "$artist" ] && [ -n "$title" ]; then
  text="$artist - $title"
elif [ -n "$title" ]; then
  text="$title"
elif [ -n "$artist" ]; then
  text="$artist"
else
  text="..."
fi

# Corta se passar de 40 caracteres
max=40
if [ ${#text} -gt $max ]; then
  text="${text:0:$max}..."
fi

# Escapa caracteres especiais de markup
text="${text//&/&amp;}"
text="${text//</&lt;}"
text="${text//>/&gt;}"

echo "{\"text\": \"$icon $text\", \"class\": \"$class\"}"
