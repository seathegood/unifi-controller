import importlib.util
import json
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


check_unifi_version = _load_module(
    "check_unifi_version_script",
    ".github/scripts/check_unifi_version.py",
)


class _FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read(self):
        return json.dumps(self._payload).encode("utf-8")


class CheckUnifiVersionTests(unittest.TestCase):
    def test_graphql_request_returns_data_payload(self):
        payload = {"data": {"publicReleaseGroups": [{"id": "1", "title": "UniFi Network Application"}]}}
        with patch.object(check_unifi_version, "urlopen", return_value=_FakeResponse(payload)):
            data = check_unifi_version._graphql_request("query {}", {}, operation_name="X")
        self.assertIn("publicReleaseGroups", data)

    def test_graphql_request_raises_on_graphql_errors(self):
        payload = {"errors": [{"message": "bad request"}]}
        with patch.object(check_unifi_version, "urlopen", return_value=_FakeResponse(payload)):
            with self.assertRaises(RuntimeError):
                check_unifi_version._graphql_request("query {}", {})

    def test_get_group_id_selects_matching_title(self):
        fake_data = {"publicReleaseGroups": [{"id": "x1", "title": "Other"}, {"id": "x2", "title": "UniFi Network Application"}]}
        with patch.object(check_unifi_version, "_graphql_request", return_value=fake_data):
            group_id = check_unifi_version._get_group_id()
        self.assertEqual(group_id, "x2")

    def test_get_latest_ga_release_uses_first_ga_item(self):
        fake_data = {
            "releases": {
                "items": [
                    {"version": "10.0.161", "stage": "RC", "slug": "rc"},
                    {"version": "10.0.162", "stage": "GA", "slug": "ga-1"},
                    {"version": "10.0.163", "stage": "GA", "slug": "ga-2"},
                ]
            }
        }
        with patch.object(check_unifi_version, "_graphql_request", return_value=fake_data):
            latest = check_unifi_version._get_latest_ga_release("group-id")
        self.assertEqual(latest["version"], "10.0.162")
        self.assertEqual(latest["slug"], "ga-1")

    def test_load_known_versions_returns_empty_for_missing_file(self):
        missing = Path(tempfile.gettempdir()) / "definitely-missing-versions-file.txt"
        if missing.exists():
            missing.unlink()
        versions = check_unifi_version._load_known_versions(missing)
        self.assertEqual(versions, [])

    def test_main_writes_outputs_when_new_version_detected(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_path = Path(tmpdir) / "github_output.txt"
            with (
                patch.object(check_unifi_version, "_get_group_id", return_value="g1"),
                patch.object(
                    check_unifi_version,
                    "_get_latest_ga_release",
                    return_value={"version": "10.0.162", "slug": "release-slug"},
                ),
                patch.object(check_unifi_version, "_load_known_versions", return_value=[]),
                patch.dict(check_unifi_version.os.environ, {"GITHUB_OUTPUT": str(output_path)}, clear=False),
            ):
                check_unifi_version.main()

            content = output_path.read_text(encoding="utf-8")
            self.assertIn("new_version=10.0.162", content)
            self.assertIn("release_slug=release-slug", content)
            self.assertIn("release_url=https://community.ui.com/releases/release-slug", content)

    def test_main_writes_empty_outputs_when_version_already_known(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            output_path = Path(tmpdir) / "github_output.txt"
            with (
                patch.object(check_unifi_version, "_get_group_id", return_value="g1"),
                patch.object(
                    check_unifi_version,
                    "_get_latest_ga_release",
                    return_value={"version": "10.0.162", "slug": "release-slug"},
                ),
                patch.object(check_unifi_version, "_load_known_versions", return_value=["10.0.162"]),
                patch.dict(check_unifi_version.os.environ, {"GITHUB_OUTPUT": str(output_path)}, clear=False),
            ):
                with self.assertRaises(SystemExit) as ctx:
                    check_unifi_version.main()
                self.assertEqual(ctx.exception.code, 0)

            content = output_path.read_text(encoding="utf-8")
            self.assertIn("new_version=", content)
            self.assertIn("release_slug=", content)
            self.assertIn("release_url=", content)


if __name__ == "__main__":
    unittest.main()
