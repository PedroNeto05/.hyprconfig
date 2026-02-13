DIRS := $(shell for dir in *; do if [ -d "$$dir" ]; then echo $$dir; fi; done)

stow-all:
	@echo "Executando 'stow' nas seguintes pastas:"
	@for dir in $(DIRS); do \
		echo "→ stow $$dir"; \
		stow $$dir --adopt; \
	done
	@git reset .
