-- Programas usados pelos binds. Modulo compartilhado: quem precisa faz
-- `local programs = require("programs")`.
return {
    terminal    = "kitty",
    fileManager = "nautilus",
    menu        = "~/.config/rofi/launchers/type-2/launcher.sh",
    browser     = "zen-browser || flatpak run app.zen_browser.zen || firefox",
    notes       = "obsidian || flatpak run md.obsidian.Obsidian",
    quickNotes  = [[sh -c 'URI="obsidian://new?vault=notes&file=quicknotes/$(date +%Y-%m-%d_%H-%M-%S)"; obsidian "$URI" || flatpak run md.obsidian.Obsidian "$URI"']],
}
