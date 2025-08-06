import requests
import sys
import re
from packaging import version  # Requires 'pip install packaging'

URL = "https://community.ui.com/releases"

try:
    resp = requests.get(URL, timeout=10)
    resp.raise_for_status()
except requests.RequestException as e:
    print(f"Error fetching releases page: {e}", file=sys.stderr)
    sys.exit(1)

html = resp.text

# Find all version strings like "UniFi Network Application 9.3.45"
matches = re.findall(r"UniFi Network Application (\d+\.\d+\.\d+)", html)
if not matches:
    print("Error: Could not find any UniFi Network Application versions", file=sys.stderr)
    sys.exit(1)

latest_version = sorted(matches, key=version.parse, reverse=True)[0]
print(latest_version)