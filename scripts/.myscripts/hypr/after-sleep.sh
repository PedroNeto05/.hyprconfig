#!/bin/bash
#
# Roda no after_sleep_cmd do hypridle (ver hypr/.config/hypr/hypridle.conf),
# quando o PC volta da suspensão.

hyprctl dispatch 'hl.dsp.dpms({ action = "on" })'

# Na volta da suspensão a GPU AMD passa por "amdgpu: PCI CONFIG reset" e o
# hyprpaper não redesenha: a área de trabalho fica preta. Reiniciar o hyprpaper
# (pelo Hyprland, como no autostart) redesenha o papel de parede.
sleep 2
pkill -x hyprpaper
sleep 0.5
hyprctl dispatch 'hl.dsp.exec_cmd("hyprpaper")'
