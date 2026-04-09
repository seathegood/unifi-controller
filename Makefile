SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

.PHONY: bootstrap doctor check lint format format-check unit clean-local

bootstrap:
	@mkdir -p _tmp _reports
	@echo "Bootstrap complete."

doctor:
	@missing=0; \
	check_cmd() { \
		cmd="$$1"; \
		hint="$$2"; \
		if command -v "$$cmd" >/dev/null 2>&1; then \
			echo "[ok] $$cmd"; \
		else \
			echo "[missing] $$cmd - $$hint"; \
			missing=1; \
		fi; \
	}; \
	check_cmd bash "Install GNU Bash (usually preinstalled)."; \
	check_cmd python3 "Install Python 3 from https://www.python.org/downloads/."; \
	check_cmd git "Install Git from https://git-scm.com/downloads."; \
	check_cmd curl "Install curl (usually preinstalled)."; \
	check_cmd docker "Install Docker Desktop or Docker Engine."; \
	if command -v docker >/dev/null 2>&1; then \
		if docker compose version >/dev/null 2>&1; then \
			echo "[ok] docker compose"; \
		else \
			echo "[missing] docker compose - Install Docker Compose v2 plugin."; \
			missing=1; \
		fi; \
	fi; \
	if command -v hadolint >/dev/null 2>&1; then \
		echo "[ok] hadolint (optional)"; \
	else \
		echo "[warn] hadolint not found (optional, CI still enforces Dockerfile lint)."; \
	fi; \
	if [ "$$missing" -ne 0 ]; then \
		echo "Doctor checks failed."; \
		exit 1; \
	fi; \
	echo "Doctor checks passed."

lint:
	@bash -n build.sh entrypoint.sh entrypoint-functions.sh healthcheck.sh
	@python3 -m py_compile .github/scripts/check_unifi_version.py .github/scripts/update_unifi_assets.py
	@if command -v hadolint >/dev/null 2>&1; then \
		hadolint Dockerfile; \
	else \
		echo "hadolint not found locally; skipping Dockerfile lint (CI enforces this)."; \
	fi
	@echo "Lint checks passed."

format:
	@echo "No formatter configured for this repository."

format-check:
	@echo "No formatter check configured for this repository."

unit:
	@python3 -m unittest discover -s tests -p "test_*.py" -v

check: lint unit
	@echo "All checks passed."

clean-local:
	@rm -rf _tmp _reports __pycache__ .pytest_cache
	@find . -type d -name __pycache__ -prune -exec rm -rf {} +
	@find . -type f -name "*.pyc" -delete
	@echo "Local transient artifacts cleaned."
