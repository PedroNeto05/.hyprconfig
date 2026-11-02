-- See https://wiki.hypr.land/configuring/core/binds/

local programs = require("programs")
local mainMod  = "SUPER" -- Tecla "Windows" como modificador principal

-- Monta a string de teclas: key(mainMod, "SHIFT", "N") -> "SUPER + SHIFT + N".
local function key(...)
    return table.concat({ ... }, " + ")
end

local exec = hl.dsp.exec_cmd

hl.bind(key(mainMod, "T"),      exec(programs.terminal))
hl.bind(key(mainMod, "Q"),      hl.dsp.window.close())
hl.bind(key(mainMod, "C"),      exec("~/.config/rofi/clipboard/type-1/clipboard.sh"))
hl.bind(key(mainMod, "P"),      exec("hyprpicker -a"))
hl.bind(key(mainMod, "R"),      exec("bash -lc 'pkill -USR1 waybar'"))
hl.bind(key(mainMod, "B"),      exec(programs.browser))
hl.bind(key(mainMod, "ESCAPE"), exec("~/.config/rofi/powermenu/type-2/powermenu.sh"))
hl.bind(key(mainMod, "F"),      hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(key(mainMod, "E"),      exec(programs.fileManager))
hl.bind(key(mainMod, "V"),      hl.dsp.window.float({ action = "toggle" }))
hl.bind(key(mainMod, "SPACE"),  exec(programs.menu))
hl.bind(key(mainMod, "L"),      exec("hyprlock"))
hl.bind("Print",                exec("~/.config/rofi/screenshot/type-1/screenshot.sh"))
hl.bind(key("SHIFT", "Print"),  exec("~/.config/rofi/screenshot/type-1/screenshot.sh area"))
hl.bind(key(mainMod, "N"),      exec(programs.notes))
hl.bind(key(mainMod, "SHIFT", "N"), exec(programs.quickNotes))

-- Move o foco com mainMod + setas
hl.bind(key(mainMod, "left"),  hl.dsp.focus({ direction = "left" }))
hl.bind(key(mainMod, "right"), hl.dsp.focus({ direction = "right" }))
hl.bind(key(mainMod, "up"),    hl.dsp.focus({ direction = "up" }))
hl.bind(key(mainMod, "down"),  hl.dsp.focus({ direction = "down" }))

-- mainMod + [0-9] troca de workspace; mainMod + SHIFT + [0-9] move a janela ativa
for i = 1, 10 do
    local k = tostring(i % 10) -- 10 vai na tecla 0
    hl.bind(key(mainMod, k),          hl.dsp.focus({ workspace = i }))
    hl.bind(key(mainMod, "SHIFT", k), hl.dsp.window.move({ workspace = i }))
end

-- Workspace especial (scratchpad)
hl.bind(key(mainMod, "S"),          hl.dsp.workspace.toggle_special("magic"))
hl.bind(key(mainMod, "SHIFT", "S"), hl.dsp.window.move({ workspace = "special:magic" }))

-- mainMod + scroll percorre os workspaces existentes
hl.bind(key(mainMod, "mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key(mainMod, "mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))

-- mainMod + LMB/RMB arrastando move/redimensiona janelas
hl.bind(key(mainMod, "mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key(mainMod, "mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Teclas multimidia de volume e brilho (antigo bindel)
local locked_repeat = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), locked_repeat)
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      locked_repeat)
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     locked_repeat)
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   locked_repeat)
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl -e4 -n2 set 5%+"),                  locked_repeat)
hl.bind("XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-"),                  locked_repeat)

-- Requer playerctl (antigo bindl)
hl.bind("XF86AudioNext",  exec("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })

-- Ditado por voz (voxtype): segure Super+D para gravar e solte para transcrever.
-- Super+Shift+D alterna gravacao, para ditados longos sem segurar a tecla.
--
-- O bind de soltura de Super+D so dispara se o Super AINDA estiver apertado
-- quando o D sobe (o Hyprland compara os mods do instante da soltura). Soltando
-- o Super primeiro, a gravacao ficava presa -- por isso soltar o proprio Super
-- tambem para. Opcoes do bind do Super (antigo bindrnt): release = na soltura,
-- non_consuming = nao engole o Super dos apps, transparent = sem ele o Super+D
-- "sombreia" o bind e ele nunca dispara.
-- O voxtype-ptt.sh so para gravacoes iniciadas por Super+D, nao as do toggle.
local ptt = "~/.myscripts/hypr/voxtype-ptt.sh"
local super_release = { release = true, non_consuming = true, transparent = true }
hl.bind(key(mainMod, "D"),          exec(ptt .. " start"))
hl.bind(key(mainMod, "D"),          exec(ptt .. " stop"), { release = true })
hl.bind(key("SUPER", "SUPER_L"),    exec(ptt .. " stop"), super_release)
hl.bind(key("SUPER", "SUPER_R"),    exec(ptt .. " stop"), super_release)
hl.bind(key(mainMod, "SHIFT", "D"), exec(ptt .. " toggle"))

-- Submap ativado pelo voxtype enquanto digita (pre/post_output_command em
-- ~/.config/voxtype/config.toml): sem binds, um Super ainda pressionado nao
-- dispara atalhos. F12 sai manualmente caso o daemon morra no meio da digitacao.
hl.define_submap("voxtype_suppress", function()
    hl.bind("F12", hl.dsp.submap("reset"))
end)
