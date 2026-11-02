-- See https://wiki.hypr.land/configuring/core/monitors/
--
-- "highrr" usa a resolucao preferida do EDID na maior taxa de atualizacao
-- disponivel. Substitui o antigo 1920x1080@144 fixo, que deixava sem imagem
-- qualquer painel com outra resolucao nativa (o caso de praticamente todo
-- notebook).
hl.monitor({
    output   = "",
    mode     = "highrr",
    position = "auto",
    scale    = "auto",
})
