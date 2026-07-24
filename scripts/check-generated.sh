#!/usr/bin/env bash
#
# Verify the generated files are up to date with their sources. Regenerates
# them and fails if the result differs from what is committed — so a push can't
# ship a stale SUPPORTED_LIST / vimdoc. Wired as a pre-push hook via pre-commit
# (see .pre-commit-config.yaml); run it directly any time to check.
#
# Requires: deno (task gen/doc), pandoc + git (vimdoc via panvimdoc).
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Files produced by the generators, checked for staleness.
GENERATED=(
  doc/SUPPORTED_LIST.md
  doc/supported-list.json
  doc/efmls-configs.txt
)

command -v deno >/dev/null 2>&1 || { echo "error: deno is required to verify generated docs" >&2; exit 1; }
command -v pandoc >/dev/null 2>&1 || { echo "error: pandoc (>= 3) is required to verify the vimdoc" >&2; exit 1; }

deno task gen >/dev/null
deno task doc >/dev/null

if ! git diff --quiet -- "${GENERATED[@]}"; then
  {
    echo "error: generated files are out of date — regenerate and commit them:"
    git diff --name-only -- "${GENERATED[@]}" | sed 's/^/  /'
    echo
    echo "  deno task gen && deno task doc"
  } >&2
  exit 1
fi

echo "generated docs up to date"
