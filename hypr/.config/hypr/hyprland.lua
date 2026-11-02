-- Ponto de entrada da config do Hyprland (formato Lua, obrigatorio a partir
-- do 0.57, que removeu o hyprlang). Este arquivo so carrega os arquivos de
-- topico da mesma pasta: edite o topico, nao este dispatcher.
--
-- Valide qualquer mudanca com `hyprctl configerrors`: a pasta e stowada, entao
-- o Hyprland recarrega a config assim que o arquivo e salvo.

require("monitor")
require("autostart")
require("environment")
require("permissions")
require("look_and_feel")
require("input")
require("keybinds")
require("windows_and_workspaces")

-- Carregado por ultimo. Em desktop as regras daqui simplesmente nao casam com
-- nenhum dispositivo (nao ha "Lid Switch" nem teclas XF86Kbd*).
require("laptop")
