-- Configuracoes de notebook.
--
-- Sempre carregado (ultimo require do hyprland.lua). Em desktop tudo aqui e
-- no-op: nao ha "Lid Switch" nem teclas XF86Kbd*, entao nada casa.

local exec = hl.dsp.exec_cmd

-- --- Tampa (lid switch) ------------------------------------------------------
-- Estes binds reagem SO ao switch da tampa. Conectar ou desconectar um monitor
-- externo nao mexe no painel interno: quem cuida disso e a regra generica em
-- monitor.lua, que liga tudo que aparecer.
--
-- Ao FECHAR a tampa havendo monitor externo, o painel interno e desligado e a
-- sessao segue no externo. Sem monitor externo o script nao faz nada e quem
-- decide suspender/bloquear e o systemd-logind
-- (/etc/systemd/logind.conf.d/90-laptop-lid.conf, ver modules/post/03_laptop.sh).
-- locked = dispara mesmo com a sessao bloqueada.
hl.bind("switch:on:Lid Switch",  exec("~/.myscripts/hypr/lid.sh close"), { locked = true })
hl.bind("switch:off:Lid Switch", exec("~/.myscripts/hypr/lid.sh open"),  { locked = true })

-- --- Economia de energia -----------------------------------------------------
-- VFR (reduzir redesenho com a tela parada) deixou de ser opcao a partir do
-- Hyprland 0.5x: hoje e sempre ativo. Sobrou o VRR/adaptive sync, aplicado
-- apenas onde o painel anuncia suporte.
hl.config({
    misc = {
        vrr = 1,
    },
})

-- --- Teclas de hardware extras de notebook -----------------------------------
-- Retroiluminacao do teclado (quando exposta como led "*::kbd_backlight").
hl.bind("XF86KbdBrightnessUp",   exec([[brightnessctl -d "*::kbd_backlight" set +33%]]), { locked = true, repeating = true })
hl.bind("XF86KbdBrightnessDown", exec([[brightnessctl -d "*::kbd_backlight" set 33%-]]), { locked = true, repeating = true })

-- Tecla de modo aviao e tecla de suspender.
hl.bind("XF86RFKill", exec("rfkill toggle all"),     { locked = true })
hl.bind("XF86Sleep",  exec("systemctl suspend"),     { locked = true })

-- Alterna o perfil de energia (mesma acao do clique no widget da waybar).
hl.bind("SUPER + SHIFT + P", exec("~/.config/waybar/scripts/power-profile.sh next"))
