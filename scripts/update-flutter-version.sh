#!/usr/bin/env bash
#
# Writes the current Flutter stable release from the official release index
# to the FLUTTER_VERSION file. Run by the "Check Flutter version" workflow,
# safe to run locally (requires curl and jq).

set -euo pipefail

VERSION_FILE="${VERSION_FILE:-FLUTTER_VERSION}"
RELEASES_URL="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"

version=$(curl -fsSL "$RELEASES_URL" | jq -r '
    .current_release.stable as $hash
    | first(.releases[] | select(.hash == $hash and .channel == "stable") | .version) // empty
')

if [ -z "$version" ]; then
    echo "Error: could not resolve the current stable release" >&2
    exit 1
fi

echo "Latest stable version: $version"
echo "$version" >"$VERSION_FILE"
