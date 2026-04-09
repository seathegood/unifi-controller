import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


def _load_module(module_name: str, relative_path: str):
    module_path = Path(__file__).resolve().parents[1] / relative_path
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


update_unifi_assets = _load_module(
    "update_unifi_assets_script",
    ".github/scripts/update_unifi_assets.py",
)


class UpdateUnifiAssetsTests(unittest.TestCase):
    def test_update_dockerfile_replaces_version_line(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            dockerfile = Path(tmpdir) / "Dockerfile"
            dockerfile.write_text("ARG UNIFI_CONTROLLER_VERSION=10.0.100\nFROM debian:bookworm-slim\n", encoding="utf-8")

            with patch.object(update_unifi_assets, "DOCKERFILE_PATH", dockerfile):
                update_unifi_assets._update_dockerfile("10.0.162")

            content = dockerfile.read_text(encoding="utf-8")
            self.assertIn("ARG UNIFI_CONTROLLER_VERSION=10.0.162", content)
            self.assertNotIn("ARG UNIFI_CONTROLLER_VERSION=10.0.100", content)

    def test_update_dockerfile_raises_when_marker_missing(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            dockerfile = Path(tmpdir) / "Dockerfile"
            dockerfile.write_text("FROM debian:bookworm-slim\n", encoding="utf-8")

            with patch.object(update_unifi_assets, "DOCKERFILE_PATH", dockerfile):
                with self.assertRaises(RuntimeError):
                    update_unifi_assets._update_dockerfile("10.0.162")

    def test_update_versions_file_appends_new_version(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            versions = Path(tmpdir) / "versions.txt"
            versions.write_text("10.0.160", encoding="utf-8")

            with patch.object(update_unifi_assets, "VERSIONS_PATH", versions):
                update_unifi_assets._update_versions_file("10.0.162")

            content = versions.read_text(encoding="utf-8")
            self.assertEqual(content, "10.0.160\n10.0.162\n")

    def test_update_versions_file_does_not_duplicate_existing_version(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            versions = Path(tmpdir) / "versions.txt"
            versions.write_text("10.0.160\n10.0.162\n", encoding="utf-8")

            with patch.object(update_unifi_assets, "VERSIONS_PATH", versions):
                update_unifi_assets._update_versions_file("10.0.162")

            content = versions.read_text(encoding="utf-8")
            self.assertEqual(content, "10.0.160\n10.0.162\n")


if __name__ == "__main__":
    unittest.main()
