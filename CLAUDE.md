# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles for an **Arch Linux + Hyprland (Wayland)** desktop. There is no build/test/lint
suite — this repo is configuration plus shell/Python installer scripts. Comments, notifications, and
log messages are written in **Portuguese (pt-BR)**; keep that language when editing them.

## Stow layout (the core convention)

Dotfiles are deployed with **GNU Stow**, not copied. Each top-level directory (`hypr`, `waybar`,
`rofi`, `themes`, `scripts`, `systemd-daemons`, `nautilus-scripts`, etc.) is a *stow package* whose
internal tree mirrors `$HOME`. For example `hypr/.config/hypr/hyprland.conf` is symlinked to
`~/.config/hypr/hyprland.conf`. When adding a new config file, place it at the real path it should
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
  `modules/post/04_voxtype.sh` (`configure_voxtype`), `modules/post/03_laptop.sh`
  (`configure_laptop`) and finally `modules/post/02_daemons.sh`.

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
  `keybinds.conf`. The daemon starts via `exec-once` in `autostart.conf`, **not** the packaged
  systemd unit — without uwsm `graphical-session.target` never activates. `configure_voxtype`
  switches to the Vulkan binary (`sudo voxtype setup gpu --enable`) and downloads the model.
  Visual feedback: the daemon spawns its own OSD (`voxtype-osd-gtk4`, needs `gtk4-layer-shell`)
  while recording, and Waybar has a `custom/voxtype` module (`voxtype status --follow`). Note
  GTK CSS rejects comma-separated keyframe selectors (`0%, 100%`) — a bad rule kills Waybar.
- README references `./pre-install.sh`, but the actual file is `./pre.sh`.

## Hyprland config

`hypr/.config/hypr/hyprland.conf` is only a dispatcher: it `source`s topic files in the same dir
(`monitor.conf`, `programs.conf`, `autostart.conf`, `environment.conf`, `permissions.conf`,
`look_and_feel.conf`, `input.conf`, `keybinds.conf`, `windows_and_workspaces.conf`, and last
`laptop.conf`). Edit the relevant topic file, not the dispatcher.

`laptop.conf` is sourced **last** because it uses `$mainMod` from `keybinds.conf`. It is always
loaded on every machine — on a desktop none of its rules match a real device (no `Lid Switch`, no
`XF86Kbd*` keys), so it needs no conditional source. Validate any change with
`hyprctl configerrors`: the configs are stowed, so Hyprland reloads them the moment you save.

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
