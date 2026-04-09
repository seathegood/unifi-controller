# Local Development Notes

## Local Work Contract
- Use `make bootstrap` to create local transient directories.
- Use `make doctor` to verify required local tooling.
- Use `make check` before opening or merging changes.
- Use `make clean-local` to remove transient local artifacts.

## Local-Only Artifacts
- `_tmp/`: transient local artifacts.
- `_reports/`: generated local outputs and reports.
- `.venv/`: optional repo-root Python virtual environment.
- `.env`: local runtime overrides (do not commit).

## Runtime Data Mounts
These paths are local runtime state and should stay untracked:
- `mongo/data/`
- `unifi-controller/cert/`
- `unifi-controller/data/`
- `unifi-controller/logs/`

## Environment Variables
Copy `.env.example` to `.env` and adjust as needed.

Required:
- `DB_MONGO_LOCAL`
- `DB_MONGO_URI`
- `STATDB_MONGO_URI`
- `UNIFI_DB_NAME`

Optional:
- `TZ`
- `DOCKER_RESTART_POLICY`
- `UNIFI_PORTAL_HEALTHCHECK_TEST`

## Python Environment Helpers
Unix/macOS:
```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m unittest discover -s tests -p "test_*.py" -v
```

Windows PowerShell:
```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
python -m unittest discover -s tests -p "test_*.py" -v
```

Windows Command Prompt:
```bat
py -m venv .venv
.venv\Scripts\activate.bat
python -m unittest discover -s tests -p "test_*.py" -v
```
