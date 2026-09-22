# Makefile for dev-snippets. Runs the checks and a couple of helpers.
# Nothing here needs to be installed except python3, bash, and (optionally)
# shellcheck. `make help` lists targets.
#
# Note: recipe lines MUST start with a real tab, not spaces. If you copy this
# and make says "missing separator", your editor converted tabs to spaces.

SHELL := /usr/bin/env bash
PYTHON ?= python3
SHELLCHECK ?= shellcheck

PY_FILES := $(wildcard python/*.py)
SH_FILES := $(wildcard shell/*.sh) $(wildcard git/*.sh)

.PHONY: help check py-check sh-check sh-lint fmt demo clean

help: ## show this help
	@echo "targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

check: py-check sh-lint ## run all checks (syntax + shell lint)

py-check: ## compile every python snippet (syntax only, no execution)
	@for f in $(PY_FILES); do \
		$(PYTHON) -m py_compile "$$f" && echo "ok  $$f" || exit 1; \
	done

sh-check: ## bash syntax check every shell script
	@for f in $(SH_FILES); do \
		bash -n "$$f" && echo "ok  $$f" || exit 1; \
	done

sh-lint: sh-check ## shellcheck (skips gracefully if not installed)
	@if command -v $(SHELLCHECK) >/dev/null 2>&1; then \
		$(SHELLCHECK) $(SH_FILES) || true; \
	else \
		echo "shellcheck not installed, skipping (brew install shellcheck)"; \
	fi

fmt: ## show the tree, for a quick sanity glance
	@find . -type f \( -name '*.py' -o -name '*.sh' -o -name '*.sql' \
		-o -name 'Makefile' -o -name '*.md' \) | sort

demo: ## run the python snippets' self-tests
	$(PYTHON) python/retry.py
	$(PYTHON) python/cache_decorator.py
	$(PYTHON) python/parallel_map.py

clean: ## remove __pycache__ left behind by py_compile
	@find . -type d -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true
	@echo "cleaned"
