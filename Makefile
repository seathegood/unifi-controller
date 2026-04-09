SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

.PHONY: bootstrap doctor check lint format format-check unit clean-local

bootstrap:
	@mkdir -p _tmp _reports
	@echo "Bootstrap complete."

doctor:
	@command -v bash >/dev/null
	@command -v python3 >/dev/null
	@command -v docker >/dev/null
	@docker compose version >/dev/null
	@echo "Doctor checks passed."

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
