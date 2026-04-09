# AGENTS.md

## Purpose
Operational guidance for coding agents working in this repository.

## Command Contract
- Use `make` targets as the primary interface.
- Start with `make doctor` to validate local prerequisites.
- Run `make check` before proposing or merging changes.
- Prefer extending the `Makefile` over introducing one-off ad hoc commands in docs/CI.

## Standard Targets
- `make bootstrap`: create local transient directories (`_tmp`, `_reports`).
- `make doctor`: verify required local tools (`bash`, `python3`, `docker`, `docker compose`).
- `make lint`: shell syntax checks, Python script compilation, optional `hadolint`.
- `make unit`: lightweight script-level verification (no full runtime integration tests).
- `make check`: aggregate verification target used by humans, CI, and agents.
- `make clean-local`: remove local transient/cache artifacts only.

## Repository Conventions
- `_tmp/` is for local transient artifacts and must remain untracked.
- `_reports/` is for generated local outputs and must remain untracked.
- `.venv/` is optional local tooling environment and must remain untracked.
- `.env` is local-only; keep `.env.example` as the committed contract reference.
- Do not commit runtime volume data under `mongo/data` or `unifi-controller/{cert,data,logs}`.

## CI Alignment
- CI should call `make check` where practical to preserve a shared validation contract.
- Keep release automation behavior stable unless explicitly requested.

## Safety Expectations
- Prefer safe, incremental refactors.
- Avoid destructive cleanup of user/runtime data.
- Flag uncertain architecture changes instead of guessing intent.
