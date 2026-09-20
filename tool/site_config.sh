#!/usr/bin/env bash
#
# Regenerates site/config.json.
#
# The site reads its own values (author, links, stores) from this file, which
# git ignores. The version is never typed here: it comes from pubspec.yaml, the
# single place a release bump already happens.
#
# Local preview: run this after bumping the version.
# Pages: the deploy job writes the file from the SITE_CONFIG_JSON secret first,
# then runs this same script, so both paths agree.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if [ ! -f site/config.json ]; then
    cp site/config.json.dist site/config.json
fi

version="$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*//')"
version="${version%%+*}"

python3 - "$version" <<'PY'
import json
import sys

path = "site/config.json"
with open(path, encoding="utf-8") as handle:
    config = json.load(handle)
config["version"] = sys.argv[1]
with open(path, "w", encoding="utf-8") as handle:
    json.dump(config, handle, indent=2, ensure_ascii=False)
    handle.write("\n")
PY

echo "site/config.json: version ${version}"
