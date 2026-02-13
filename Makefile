HOME_PKGS = hyprland rofi waybar wallpapers scripts
ROOT_PKGS = sddm plymouth refind

STOW = stow
STOW_FLAGS = --verbose

.PHONY: home root all delete-home delete-root

home:
	@echo "🔹 Instalando pacotes na HOME"
	@for dir in $(HOME_PKGS); do \
		echo "→ stow $$dir (HOME)"; \
		$(STOW) $(STOW_FLAGS) --target=$$HOME $$dir; \
	done

root:
	@echo "🔹 Instalando pacotes no / (sudo necessário)"
	@for dir in $(ROOT_PKGS); do \
		echo "→ stow $$dir (/)"; \
		sudo $(STOW) $(STOW_FLAGS) --target=/ $$dir; \
	done

all: home root

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
