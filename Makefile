HOME_PKGS = hyprland rofi waybar wallpapers scripts
ROOT_PKGS = sddm plymouth
REFIND_PKG = refind

STOW = stow
STOW_FLAGS = --verbose

.PHONY: home root refind all delete-home delete-root delete-refind

# ==============================
# HOME
# ==============================

home:
	@echo "🔹 Instalando pacotes na HOME"
	@for dir in $(HOME_PKGS); do \
		echo "→ stow $$dir (HOME)"; \
		$(STOW) $(STOW_FLAGS) --target=$$HOME $$dir; \
	done

# ==============================
# ROOT (exceto refind)
# ==============================

root:
	@echo "🔹 Instalando pacotes no / (sudo necessário)"
	@for dir in $(ROOT_PKGS); do \
		echo "→ stow $$dir (/)"; \
		sudo $(STOW) $(STOW_FLAGS) --target=/ $$dir; \
	done

# ==============================
# rEFInd (tratamento especial)
# ==============================

refind:
	@echo "🔹 Instalando configs do rEFInd"
	@echo "→ Criando backup se existir"
	@sudo mv -n /boot/EFI/refind/refind.conf /boot/EFI/refind/refind.conf.bak 2>/dev/null || true
	@sudo mv -n /boot/refind_linux.conf /boot/refind_linux.conf.bak 2>/dev/null || true
	@echo "→ Aplicando stow para rEFInd"
	@sudo $(STOW) $(STOW_FLAGS) --target=/ $(REFIND_PKG)

# ==============================
# ALL
# ==============================

all: home root refind

# ==============================
# DELETE
# ==============================

delete-home:
	@for dir in $(HOME_PKGS); do \
		echo "→ unstow $$dir (HOME)"; \
		$(STOW) -D --target=$$HOME $$dir; \
	done

delete-root:
	@for dir in $(ROOT_PKGS); do \
		echo "→ unstow $$dir (/)"; \
		sudo $(STOW) -D --target=/ $$dir; \
	done

delete-refind:
	@echo "→ unstow refind (/)"
	@sudo $(STOW) -D --target=/ $(REFIND_PKG)

