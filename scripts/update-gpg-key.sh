#!/usr/bin/env bash
set -euo pipefail

# Update HashiCorp GPG key in vault/defaults.yaml
# Usage: ./scripts/update-gpg-key.sh [fingerprint]
#
# If no fingerprint is provided, fetches the key from HashiCorp's website.

DEFAULTS_FILE="$(cd "$(dirname "$0")/.." && pwd)/vault/defaults.yaml"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

GNUPGHOME="$TMPDIR/gnupg"
export GNUPGHOME
mkdir -m 700 "$GNUPGHOME"

if [[ $# -ge 1 ]]; then
    FINGERPRINT="$1"
    echo "Fetching key $FINGERPRINT from keyserver..."
    gpg --keyserver keyserver.ubuntu.com --recv-keys "$FINGERPRINT"
else
    echo "Fetching key from https://www.hashicorp.com/.well-known/pgp-key.txt ..."
    curl -sS https://www.hashicorp.com/.well-known/pgp-key.txt -o "$TMPDIR/hashicorp.asc"
    gpg --import "$TMPDIR/hashicorp.asc"
    # Get the fingerprint of the first imported key
    FINGERPRINT=$(gpg --list-keys --with-colons 2>/dev/null | awk -F: '/^fpr/{print $10; exit}')
    echo "Detected fingerprint: $FINGERPRINT"
fi

# Export the key in armor format
GPG_KEY=$(gpg --armor --export "$FINGERPRINT")

if [[ -z "$GPG_KEY" ]]; then
    echo "ERROR: Failed to export key $FINGERPRINT" >&2
    exit 1
fi

echo "Updating $DEFAULTS_FILE ..."

# Build the indented key (4 spaces for YAML)
INDENTED_KEY=$(echo "$GPG_KEY" | sed 's/^/    /')

# Use python for reliable YAML-safe replacement
python3 << PYEOF
import re

with open("$DEFAULTS_FILE", "r") as f:
    content = f.read()

# Replace hashicorp_key_id
content = re.sub(
    r'(hashicorp_key_id:\s*).*',
    r'\g<1>$FINGERPRINT',
    content,
    count=1
)

# Replace hashicorp_gpg_key block
# Match from "hashicorp_gpg_key: |" until the next non-indented key or "old_hashicorp"
new_key = """hashicorp_gpg_key: |
$INDENTED_KEY"""

content = re.sub(
    r'hashicorp_gpg_key: \|.*?(?=\n  old_hashicorp|\n  [a-z]|\Z)',
    new_key,
    content,
    flags=re.DOTALL,
    count=1
)

with open("$DEFAULTS_FILE", "w") as f:
    f.write(content)

PYEOF

echo "Done. Key $FINGERPRINT written to defaults.yaml"
echo ""
echo "Don't forget to also update gpg/init.sls if the key_id variable name changed."
