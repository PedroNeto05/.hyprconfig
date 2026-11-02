-- See https://wiki.hypr.land/configuring/core/autostart/
-- Equivalente ao antigo exec-once: roda uma unica vez, quando o Hyprland sobe
-- (nao a cada reload da config).

local startup = {
    "waybar",
    "dunst",
    "wl-paste --type text --watch cliphist store -max-items 500",
    "wl-paste --type image --watch cliphist store -max-items 500",
    "hyprpaper",
    "hypridle",
    "hyprsunset",

    -- O processo do Hyprland fica fora do session-N.scope do logind, entao o que
    -- ele lanca "nao tem sessao" e o agente polkit morre com "No session for
    -- pid". Rodar numa scope do systemd --user resolve (o polkit acha a sessao
    -- grafica do usuario). O corectrl precisa disso pelo mesmo motivo: o helper
    -- dele autentica via polkit ("Cannot start helper").
    "systemd-run --user --scope --quiet --unit=polkit-gnome-agent /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",

    -- corectrl so e instalado em desktop com GPU AMD (ver PKG_GPU_TUNING_AMD); o
    -- teste evita um erro de startup em notebook ou em maquina Intel/NVIDIA.
    "sh -c 'command -v corectrl >/dev/null && exec systemd-run --user --scope --quiet --unit=corectrl corectrl --minimize-systray'",

    -- Vigia a remocao de monitor com a tampa fechada (ver monitor-guard.sh).
    -- Em desktop o script sai imediatamente, por nao haver painel interno.
    "~/.myscripts/hypr/monitor-guard.sh",

    -- Daemon do ditado por voz (ver modules/post/04_voxtype.sh). Sobe aqui e nao
    -- pela unit systemd do pacote: sem uwsm o graphical-session.target nunca fica
    -- ativo, e o daemon precisa herdar WAYLAND_DISPLAY (wtype) e
    -- HYPRLAND_INSTANCE_SIGNATURE (hyprctl).
    "sh -c 'command -v voxtype >/dev/null && voxtype -q daemon'",
}

hl.on("hyprland.start", function()
    for _, cmd in ipairs(startup) do
        hl.exec_cmd(cmd)
    end
end)
