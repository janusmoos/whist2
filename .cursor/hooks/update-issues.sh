#!/usr/bin/env bash
set -euo pipefail

REPO="janusmoos/whist2"
OUT_FILE="docs/issues.md"

if ! command -v gh >/dev/null 2>&1; then
  exit 0
fi

# Ikke blokér Cursor hvis man ikke er logget ind endnu.
if ! gh auth status >/dev/null 2>&1; then
  exit 0
fi

mkdir -p "$(dirname "$OUT_FILE")"

{
  echo "# Issues (auto-opdateret)"
  echo
  echo "_Genereret: $(date '+%Y-%m-%d %H:%M:%S')_"
  echo
  echo "Repo: https://github.com/$REPO"
  echo
  echo "## Åbne issues"
  echo
  gh issue list -R "$REPO" --limit 200
  echo
  echo "## Hurtige links"
  echo
  echo "- Opret nyt issue: https://github.com/$REPO/issues/new"
  echo "- Issues i browser: https://github.com/$REPO/issues"
} > "$OUT_FILE"

exit 0

