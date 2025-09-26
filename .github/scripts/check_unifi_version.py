import json
import sys
from pathlib import Path
from typing import Optional
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


GRAPHQL_ENDPOINT = "https://community.svc.ui.com/graphql"
APP_TITLE = "UniFi Network Application"
REQUEST_HEADERS = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "User-Agent": "check-unifi-version/1.0 (+https://github.com/unifi-controller)",
}
REQUEST_TIMEOUT = 15
RESULT_LIMIT = 50

GROUPS_QUERY = """
query GetPublicReleaseGroups {
  publicReleaseGroups {
    id
    title
  }
}
"""

RELEASES_QUERY = """
query GetReleaseVersionHistory($limit: Int!, $groupId: ID!, $betas: [String!], $alphas: [String!]) {
  releases(limit: $limit, groupId: $groupId, betas: $betas, alphas: $alphas) {
    items {
      version
      stage
    }
  }
}
"""


def _graphql_request(query: str, variables: dict, operation_name: Optional[str] = None) -> dict:
    payload = json.dumps({
        "operationName": operation_name,
        "query": query,
        "variables": variables,
    }).encode("utf-8")

    request = Request(GRAPHQL_ENDPOINT, data=payload, headers=REQUEST_HEADERS)

    try:
        with urlopen(request, timeout=REQUEST_TIMEOUT) as response:
            raw_body = response.read()
    except (HTTPError, URLError, TimeoutError) as exc:
        raise RuntimeError(f"Network error while contacting community API: {exc}") from exc

    try:
        body = json.loads(raw_body.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError("Received invalid JSON from community API") from exc

    errors = body.get("errors") or []
    if errors:
        messages = "; ".join(error.get("message", "Unknown error") for error in errors)
        raise RuntimeError(f"GraphQL error: {messages}")

    data = body.get("data")
    if data is None:
        raise RuntimeError("GraphQL response did not include data payload")

    return data


def _get_group_id() -> str:
    data = _graphql_request(GROUPS_QUERY, {}, operation_name="GetPublicReleaseGroups")
    for group in data.get("publicReleaseGroups", []):
        if group.get("title") == APP_TITLE and group.get("id"):
            return group["id"]
    raise RuntimeError(f"Could not locate release group for '{APP_TITLE}'")


def _get_latest_ga_version(group_id: str) -> str:
    data = _graphql_request(
        RELEASES_QUERY,
        {"limit": RESULT_LIMIT, "groupId": group_id, "betas": None, "alphas": None},
        operation_name="GetReleaseVersionHistory",
    )

    releases = data.get("releases", {}).get("items", [])
    if not releases:
        raise RuntimeError("Community API returned no releases for the group")

    for release in releases:
        if release.get("stage") == "GA" and release.get("version"):
            return release["version"]

    raise RuntimeError("No GA releases available for the UniFi Network Application")


def _load_known_versions(path: Path) -> list[str]:
    if not path.exists():
        return []

    try:
        return [line.strip() for line in path.read_text().splitlines() if line.strip()]
    except OSError as exc:
        raise RuntimeError(f"Unable to read versions file '{path}': {exc}") from exc


def main() -> None:
    try:
        group_id = _get_group_id()
        latest_version = _get_latest_ga_version(group_id)
        known_versions = _load_known_versions(Path("./versions.txt"))
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)

    if latest_version in known_versions:
        sys.exit(0)

    print(latest_version)


if __name__ == "__main__":
    main()
