"""Update repository files to reference a new UniFi Network Application version."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[2]
DOCKERFILE_PATH = REPO_ROOT / "Dockerfile"
VERSIONS_PATH = REPO_ROOT / "versions.txt"


def _update_dockerfile(version: str) -> None:
    try:
        original = DOCKERFILE_PATH.read_text()
    except OSError as exc:  # pragma: no cover - surface friendly message in workflow
        raise RuntimeError(f"Unable to read Dockerfile: {exc}") from exc

    marker = "ARG UNIFI_CONTROLLER_VERSION="
    replacement_line = f"{marker}{version}"

    updated_lines: list[str] = []
    replaced = False
    for line in original.splitlines():
        if line.startswith(marker):
            updated_lines.append(replacement_line)
            replaced = True
        else:
            updated_lines.append(line)

    if not replaced:
        raise RuntimeError("Could not locate UNIFI_CONTROLLER_VERSION argument in Dockerfile")

    DOCKERFILE_PATH.write_text("\n".join(updated_lines) + "\n")


def _update_versions_file(version: str) -> None:
    existing_content = ""
    existing: Iterable[str] = []
    if VERSIONS_PATH.exists():
        try:
            existing_content = VERSIONS_PATH.read_text()
            existing = [line.strip() for line in existing_content.splitlines() if line.strip()]
        except OSError as exc:
            raise RuntimeError(f"Unable to read versions file: {exc}") from exc

    if version in existing:
        return

    try:
        with VERSIONS_PATH.open("a", encoding="utf-8") as handle:
            if existing_content and not existing_content.endswith("\n"):
                handle.write("\n")
            handle.write(f"{version}\n")
    except OSError as exc:
        raise RuntimeError(f"Unable to append to versions file: {exc}") from exc


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", help="New UniFi Network Application version")
    args = parser.parse_args()

    version = args.version.strip()
    if not version:
        parser.error("version must not be empty")

    _update_dockerfile(version)
    _update_versions_file(version)
    return 0


if __name__ == "__main__":  # pragma: no cover - simple CLI wrapper
    sys.exit(main())
