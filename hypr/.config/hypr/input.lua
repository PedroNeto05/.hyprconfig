-- See https://wiki.hypr.land/configuring/core/config-options/ (secao input)

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "intl",
        kb_options = "",
        kb_model   = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity   = 0, -- -1.0 - 1.0, 0 means no modification.
        accel_profile = "flat",

        touchpad = {
            natural_scroll = false,
            -- Evita o cursor pular por rocar o touchpad enquanto digita.
            disable_while_typing = true,
            -- 1 dedo = esquerdo, 2 = direito, 3 = meio (em vez de dividir a barra
            -- inferior em zonas, que erra muito em touchpad grande).
            clickfinger_behavior = true,
            tap_to_click  = true,
            drag_lock     = true,
            scroll_factor = 0.8,
        },
    },
})

-- See https://wiki.hypr.land/configuring/core/gestures/
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Per-device config, see https://wiki.hypr.land/configuring/core/devices/
hl.device({
    name        = "wacom-one-by-wacom-s-pen",
    output      = "current",
    left_handed = true,
})
