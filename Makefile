EMACS ?= emacs

.PHONY: help compile recompile clean

help:
	@echo "compile    byte-compile the packages under lib/ that need it"
	@echo "recompile  byte-compile them all, even the up to date ones"
	@echo "clean      remove every .elc under lib/"
	@echo ""
	@echo "Override the binary with: make compile EMACS=/path/to/emacs"

compile:
	$(EMACS) --quick --batch --load tools/compile.el

recompile:
	FORCE=1 $(EMACS) --quick --batch --load tools/compile.el

clean:
	find lib -name '*.elc' -delete
