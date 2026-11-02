# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles for an **Arch Linux + Hyprland (Wayland)** desktop. There is no build/test/lint
suite — this repo is configuration plus shell/Python installer scripts. Comments, notifications, and
log messages are written in **Portuguese (pt-BR)**; keep that language when editing them.

## Stow layout (the core convention)

Dotfiles are deployed with **GNU Stow**, not copied. Each top-level directory (`hypr`, `waybar`,
`rofi`, `themes`, `scripts`, `systemd-daemons`, `nautilus-scripts`, etc.) is a *stow package* whose
internal tree mirrors `$HOME`. For example `hypr/.config/hypr/hyprland.lua` is symlinked to
`~/.config/hypr/hyprland.lua`. When adding a new config file, place it at the real path it should
occupy under `$HOME`, prefixed by its package directory.

The list of packages that actually get stowed lives in `PACKAGES` inside
`modules/pre/02_environment.sh` — a new top-level package dir is ignored until added there.

## Installation flow

Two entrypoints, run in order; both resolve their own dir into `$DOTFILES_DIR`/`$SCRIPT_DIR` and
`source` modules that define functions:

- `./pre.sh` → `modules/pre/01_dependencies.sh` (pacman essentials + bootstraps `yay`) then
  `modules/pre/02_environment.sh` (stows packages, installs rofi fonts, clones `~/.dotfiles` and
  runs its `stow.sh`, conditionally runs `03_btrfs.sh` if `snapper` is present, installs tmux TPM).
- `./install.sh [--gaming] [--plymouth] [--cpu V] [--gpu V]` → `modules/install/00_hardware.sh`
  (CPU/GPU/chassis detection) → `modules/install/01_packages.sh` (`install_main_packages`)
  then `modules/post/01_system_config.sh` (`configure_post_installation`), which invokes
  `modules/post/05_bluetooth.sh` (`configure_bluetooth`), `modules/post/04_voxtype.sh`
  (`configure_voxtype`), `modules/post/03_laptop.sh` (`configure_laptop`) and finally
  `modules/post/02_daemons.sh`.

Notes:
- Package lists in `01_packages.sh` are grouped bash arrays (`PKG_*`); flags and detected tooling
  (snapper/grub) append extra packages conditionally. Everything is installed via `yay`.
- `00_hardware.sh` also exports `IS_LAPTOP` / `HAS_HYBRID_GPU` via `collect_laptop_packages`
  (battery in `/sys/class/power_supply/BAT*`, `hostnamectl chassis`, DMI `chassis_type`). This
  gates both directions: `PKG_LAPTOP` + `LAPTOP_PACKAGES` are added on laptops, while
  `PKG_GPU_TUNING_AMD` (corectrl, radeontop) and `gamescope-session-cachyos` are desktop-only.
  There is deliberately **no `--notebook` flag** — detection is automatic.
- `02_daemons.sh` enables every `*.service`/`*.timer` in `~/.config/systemd/user` (so the daemon
  must be stowed there first — see `systemd-daemons/`).
- Voice dictation (`voxtype-bin`, `PKG_DICTATION`): config in the `voxtype` stow package
  (multilingual `large-v3-turbo`, `language = ["pt", "en"]`), push-to-talk on Super+D in
  `keybinds.lua`. The daemon starts via the `hyprland.start` hook in `autostart.lua`, **not** the packaged
  systemd unit — without uwsm `graphical-session.target` never activates. `configure_voxtype`
  switches to the Vulkan binary (`sudo voxtype setup gpu --enable`) and downloads the model.
  Visual feedback: the Waybar `custom/voxtype` module (`voxtype status --follow`) plus dunst
  notifications for recording start, stop (processing) and transcription. The floating OSD
  (`voxtype-osd-gtk4`) is deliberately not installed — `gtk4-layer-shell` is left out on purpose. Note
  GTK CSS rejects comma-separated keyframe selectors (`0%, 100%`) — a bad rule kills Waybar.
- Bluetooth (`05_bluetooth.sh` + `wireplumber` stow package), JBL Xtreme facts verified with btmon:
  (1) on power-on the speaker SDP-searches *Handsfree Audio Gateway* and disconnects if absent, so
  HFP AG must stay enabled — `52-bluez-hfp-ag.conf` turns it on (autoswitch-to-headset off,
  `bluez5.auto-connect = [ hfp_hf a2dp_sink ]`) and the module deletes the old
  `/etc/wireplumber/.../51-disable-bluez-hfp.conf`; (2) when the PC starts A2DP the speaker closes
  AVDTP ~10 ms after our SetConfiguration (`No reply to SetConfiguration request`) and configures
  itself; sometimes BlueZ 5.87 then wedges a2dp-sink with EBUSY (`br-connection-busy`) until
  `bluetooth.service` restarts. The module installs a *system* unit `bt-a2dp-watchdog.service`
  (needs root, so not in the user-level `systemd-daemons/`) that restarts bluetoothd only on the
  EBUSY line and only if no A2DP transport (`dev_<MAC>/sepN/fdN` in `busctl tree`) appears within
  8 s — never on `No reply` (restarting there killed the speaker's own setup); min 5 s apart,
  max 4 per 10 min; clearing the `[Endpoints]` A2DP cache was tried and did not help. It also removes
  the obsolete `reload-btusb.service`. A *different* dual-boot failure — blueman "Unknown error", log
  `Permission denied (13)` / `Too many levels of symbolic links (40)` — is a Windows/Linux link-key
  mismatch: fix with `sudo bash ~/.myscripts/bluetooth/bt-sync-windows-keys.sh`, which copies the
  Windows BR/EDR keys into `/var/lib/bluetooth` (README → "Bluetooth em dual boot com o Windows").
- README references `./pre-install.sh`, but the actual file is `./pre.sh`.

## Hyprland config

Hyprland >= 0.57 only reads **Lua** (`hyprland.lua`); hyprlang `.conf` support was removed upstream.
The other hypr* tools (`hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf`, `hyprsunset.conf`) are
separate programs and still use hyprlang. API reference: `/usr/share/hypr/stubs/hl.meta.lua` and the
packaged example `/usr/share/hypr/hyprland.lua`.

`hypr/.config/hypr/hyprland.lua` is only a dispatcher: it `require`s topic modules in the same dir
(`monitor`, `autostart`, `environment`, `permissions`, `look_and_feel`, `input`, `keybinds`,
`windows_and_workspaces`, and last `laptop`). Edit the relevant topic file, not the dispatcher.
`programs.lua` returns a table of shared program commands (`local programs = require("programs")`).

`laptop.lua` is always loaded on every machine — on a desktop none of its rules match a real device
(no `Lid Switch`, no `XF86Kbd*` keys), so it needs no conditional. Validate any change with
`hyprctl configerrors` (and `hyprctl getoption <opt>` to confirm values): the configs are stowed, so
Hyprland reloads them the moment you save. Autostart (`hl.on("hyprland.start", ...)`) only runs at
compositor startup, not on reload.

Runtime control from scripts also changed: `hyprctl dispatch` takes a Lua dispatcher expression
(`hyprctl dispatch 'hl.dsp.submap("reset")'`, `'hl.dsp.dpms({ action = "off" })'`,
`'hl.dsp.exit()'`), and `hyprctl keyword` is gone — use `hyprctl eval '<lua>'` instead (e.g.
`lid.sh` toggles the panel with `hl.monitor({ output = ..., disabled = true })`).

The Hyprland process sits outside the logind `session-N.scope`, so children it spawns have "no
session" — polkit agents and polkit-backed helpers (corectrl) die. `autostart.lua` launches those
through `systemd-run --user --scope`.

## Nautilus custom scripts (Python)

A single Nautilus extension, `nautilus-scripts/.local/share/nautilus-python/extensions/dynamic_context_menu.py`,
builds a right-click "Scripts" submenu dynamically:

- It looks in `~/.config/nautilus-custom-scripts/<ext>/` where `<ext>` is the (single, shared)
  extension of the selected files (e.g. `pdf/`, `xopp/`). Mixed extensions or directories → no menu.
- Any executable file in that folder becomes a menu entry; its filename (minus extension, `_` → space,
  title-cased) is the label.
- Filename suffix `_single` means "single-file only" — such scripts are hidden when multiple files are
  selected. The script receives the selected file paths as `argv`.

The script project is a `uv` project (`nautilus-custom-scripts/pyproject.toml`, Python >= 3.14,
`pymupdf`); `uv sync` is run during post-install. Scripts use a **hardcoded venv shebang**
(`#!/home/pedro/.config/nautilus-custom-scripts/.venv/bin/python`) — preserve/adjust this for a
different user. They surface errors to the user via `notify-send` / `zenity`, not stdout.

## Conventions

- Module scripts define functions and are `source`d by the entrypoints, which rely on exported
  `$DOTFILES_DIR` / `$SCRIPT_DIR`; keep that pattern for new modules.
- Operations are written to be idempotent (existence checks before clone/create/append).
- `.gitignore` excludes `**/.venv/` and `**/default.target.wants/`.
